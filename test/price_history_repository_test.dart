import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:cryptowatch/features/crypto_detail/data/repositories/price_history_repository.dart';
import 'package:cryptowatch/shared/errors/app_exception.dart';

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient({
    this.statusCode = 200,
    this.body = '',
    this.error,
    this.delay,
  });

  final int statusCode;
  final String body;
  final Object? error;
  final Duration? delay;
  Uri? requestedUri;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestedUri = request.url;
    if (delay != null) {
      await Future<void>.delayed(delay!);
    }
    if (error != null) {
      throw error!;
    }
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      statusCode,
    );
  }
}

/// Capture les traces pour prouver qu'aucun rejet n'est silencieux.
class _TraceRecorder {
  final List<String> messages = <String>[];
  final List<Object?> errors = <Object?>[];

  void call(String message, {Object? error, StackTrace? stackTrace}) {
    messages.add(message);
    errors.add(error);
  }

  String get joined => messages.join(' | ');
}

String _bodyWithPrices(List<Object?> prices) {
  return jsonEncode(<String, Object?>{'prices': prices});
}

void main() {
  test('fetchLast7Days retourne les points CoinGecko', () async {
    final client = _FakeHttpClient(
      statusCode: 200,
      body: jsonEncode({
        'prices': [
          [1725600000000, 64000.12],
          [1725686400000, 65100],
        ],
      }),
    );

    final points =
        await PriceHistoryRepository(client).fetchLast7Days('bitcoin');

    expect(points, hasLength(2));
    expect(points.first.price, 64000.12);
    expect(
      points.first.time,
      DateTime.fromMillisecondsSinceEpoch(1725600000000),
    );
    expect(points.last.price, 65100.0);
    expect(
      client.requestedUri.toString(),
      contains('/coins/bitcoin/market_chart'),
    );
    expect(client.requestedUri.toString(), contains('days=7'));
    expect(client.requestedUri.toString(), contains('vs_currency=usd'));
  });

  test('leve ServerException si la reponse HTTP echoue', () async {
    final client = _FakeHttpClient(statusCode: 500, body: 'Server error');

    await expectLater(
      PriceHistoryRepository(client).fetchLast7Days('bitcoin'),
      throwsA(
        isA<ServerException>().having(
          (ServerException e) => e.statusCode,
          'statusCode',
          500,
        ),
      ),
    );
  });

  test('leve RateLimitException sur un 429', () async {
    final client = _FakeHttpClient(statusCode: 429, body: 'Too Many Requests');

    await expectLater(
      PriceHistoryRepository(client).fetchLast7Days('bitcoin'),
      throwsA(isA<RateLimitException>()),
    );
  });

  test('leve NetworkException si le transport echoue', () async {
    final client = _FakeHttpClient(
      error: http.ClientException('Failed host lookup'),
    );

    await expectLater(
      PriceHistoryRepository(client).fetchLast7Days('bitcoin'),
      throwsA(isA<NetworkException>()),
    );
  });

  test('leve RequestTimeoutException si la reponse depasse le delai', () async {
    final client = _FakeHttpClient(
      statusCode: 200,
      body: jsonEncode({
        'prices': [
          [1, 1],
          [2, 2],
        ],
      }),
      delay: const Duration(milliseconds: 200),
    );

    await expectLater(
      PriceHistoryRepository(
        client,
        timeout: const Duration(milliseconds: 50),
      ).fetchLast7Days('bitcoin'),
      throwsA(isA<RequestTimeoutException>()),
    );
  });

  test("leve InvalidDataException si le JSON n'est pas un objet", () async {
    final client = _FakeHttpClient(
      statusCode: 200,
      body: jsonEncode(['pas', 'un', 'objet']),
    );

    await expectLater(
      PriceHistoryRepository(client).fetchLast7Days('ethereum'),
      throwsA(isA<InvalidDataException>()),
    );
  });

  test("leve InvalidDataException si prices n'est pas une liste", () async {
    final client = _FakeHttpClient(
      statusCode: 200,
      body: jsonEncode({'prices': 'invalide'}),
    );

    await expectLater(
      PriceHistoryRepository(client).fetchLast7Days('bitcoin'),
      throwsA(isA<InvalidDataException>()),
    );
  });

  test('ignore un point invalide et garde les autres', () async {
    final client = _FakeHttpClient(
      statusCode: 200,
      body: jsonEncode({
        'prices': [
          [1725600000000, 64000.12],
          'casse',
          [1725686400000, 65100],
        ],
      }),
    );

    final points =
        await PriceHistoryRepository(client).fetchLast7Days('bitcoin');

    expect(points, hasLength(2));
    expect(points.first.price, 64000.12);
    expect(points.last.price, 65100.0);
  });

  group('aucune erreur silencieuse', () {
    test('un point rejete laisse une trace portant la cause', () async {
      final trace = _TraceRecorder();
      final client = _FakeHttpClient(
        statusCode: 200,
        body: _bodyWithPrices(<Object?>[
          <Object?>[1725600000000, 64000.12],
          <Object?>['casse', 'casse'],
        ]),
      );

      final points = await PriceHistoryRepository(
        client,
        log: trace.call,
      ).fetchLast7Days('bitcoin');

      expect(points, hasLength(1));
      expect(trace.messages, isNotEmpty, reason: 'le rejet doit etre trace');
      expect(trace.errors.whereType<FormatException>(), isNotEmpty);
    });

    test('un rejet partiel laisse un resume chiffre', () async {
      final trace = _TraceRecorder();
      final client = _FakeHttpClient(
        statusCode: 200,
        body: _bodyWithPrices(<Object?>[
          <Object?>[1725600000000, 64000.12],
          <Object?>['casse', 'casse'],
          'pas-une-paire',
        ]),
      );

      await PriceHistoryRepository(
        client,
        log: trace.call,
      ).fetchLast7Days('bitcoin');

      expect(trace.joined, contains('2'));
      expect(trace.joined, contains('3'));
    });

    test('ne trace rien quand tous les points sont valides', () async {
      final trace = _TraceRecorder();
      final client = _FakeHttpClient(
        statusCode: 200,
        body: _bodyWithPrices(<Object?>[
          <Object?>[1725600000000, 64000.12],
        ]),
      );

      await PriceHistoryRepository(
        client,
        log: trace.call,
      ).fetchLast7Days('bitcoin');

      expect(trace.messages, isEmpty);
    });
  });

  group('contrat rompu - changement de format CoinGecko', () {
    test('leve InvalidDataException si aucun point recu est exploitable', () async {
      final client = _FakeHttpClient(
        statusCode: 200,
        body: _bodyWithPrices(<Object?>[
          <Object?>['casse', 'casse'],
          <Object?>['casse', 'casse'],
        ]),
      );

      await expectLater(
        PriceHistoryRepository(client).fetchLast7Days('bitcoin'),
        throwsA(
          isA<InvalidDataException>().having(
            (InvalidDataException e) => e.reason,
            'reason',
            allOf(contains('0'), contains('2')),
          ),
        ),
      );
    });

    test('une serie vide reste une reponse legitime, pas un contrat rompu', () async {
      final client = _FakeHttpClient(
        statusCode: 200,
        body: _bodyWithPrices(<Object?>[]),
      );

      final points = await PriceHistoryRepository(
        client,
      ).fetchLast7Days('bitcoin');

      expect(points, isEmpty);
    });
  });

  group('contrat du repository', () {
    test('toutes les erreurs sortent en AppException, jamais autre chose', () async {
      final clients = <_FakeHttpClient>[
        _FakeHttpClient(statusCode: 500, body: 'boom'),
        _FakeHttpClient(statusCode: 429, body: 'slow down'),
        _FakeHttpClient(error: http.ClientException('offline')),
        _FakeHttpClient(statusCode: 200, body: 'pas du json'),
        _FakeHttpClient(statusCode: 200, body: jsonEncode(<String>['liste'])),
      ];

      for (final client in clients) {
        await expectLater(
          PriceHistoryRepository(client).fetchLast7Days('bitcoin'),
          throwsA(isA<AppException>()),
        );
      }
    });
  });
}
