import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';

import 'package:cryptowatch/features/market/data/repositories/market_repository.dart';
import 'package:cryptowatch/shared/errors/app_exception.dart';

/// Client factice : renvoie une reponse, la retarde, ou leve une erreur
/// de transport, selon ce que le test veut simuler.
class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient({
    this.statusCode = 200,
    this.body = '',
    this.error,
    this.delay,
  });

  final int statusCode;
  final String body;

  /// Erreur levee par le transport avant toute reponse (panne reseau).
  final Object? error;

  /// Retard avant la reponse, pour declencher le timeout.
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
    return http.StreamedResponse(Stream.value(utf8.encode(body)), statusCode);
  }
}

/// Capture les traces pour prouver qu'aucune erreur n'est silencieuse.
class _TraceRecorder {
  final List<String> messages = <String>[];
  final List<Object?> errors = <Object?>[];

  void call(String message, {Object? error, StackTrace? stackTrace}) {
    messages.add(message);
    errors.add(error);
  }

  String get joined => messages.join(' | ');
}

/// Une entree CoinGecko valide, avec les champs requis.
Map<String, dynamic> _validEntry({
  required String id,
  required String name,
  required String symbol,
  required double price,
}) {
  return <String, dynamic>{
    'id': id,
    'name': name,
    'symbol': symbol,
    'current_price': price,
  };
}

/// Une entree dont un champ requis est invalide : elle doit etre rejetee.
Map<String, dynamic> _brokenEntry(String id) {
  return <String, dynamic>{
    'id': id,
    'name': 'Cassee',
    'symbol': 'brk',
    'current_price': null,
  };
}

void main() {
  group('fetchTopCryptos - cas nominal', () {
    test('retourne les cryptos de CoinGecko', () async {
      final client = _FakeHttpClient(
        statusCode: 200,
        body: jsonEncode(<Map<String, dynamic>>[
          _validEntry(
            id: 'bitcoin',
            name: 'Bitcoin',
            symbol: 'btc',
            price: 45000.0,
          ),
          _validEntry(
            id: 'ethereum',
            name: 'Ethereum',
            symbol: 'eth',
            price: 3000.0,
          ),
        ]),
      );

      final cryptos = await MarketRepository(client).fetchTopCryptos();

      expect(cryptos, hasLength(2));
      expect(cryptos.first.name, 'Bitcoin');
      expect(cryptos.first.currentPrice, 45000.0);
      expect(client.requestedUri.toString(), contains('/coins/markets'));
    });

    test('retourne une liste vide si CoinGecko renvoie une liste vide', () async {
      final client = _FakeHttpClient(
        statusCode: 200,
        body: jsonEncode(<Object>[]),
      );

      final cryptos = await MarketRepository(client).fetchTopCryptos();

      expect(cryptos, isEmpty);
    });

    test('ne trace rien quand tout est valide', () async {
      final trace = _TraceRecorder();
      final client = _FakeHttpClient(
        statusCode: 200,
        body: jsonEncode(<Map<String, dynamic>>[
          _validEntry(
            id: 'bitcoin',
            name: 'Bitcoin',
            symbol: 'btc',
            price: 45000.0,
          ),
        ]),
      );

      await MarketRepository(client, log: trace.call).fetchTopCryptos();

      expect(trace.messages, isEmpty);
    });
  });

  group('fetchTopCryptos - erreurs HTTP', () {
    test('leve ServerException portant le code HTTP si la reponse echoue', () async {
      final client = _FakeHttpClient(statusCode: 500, body: 'Server error');

      await expectLater(
        MarketRepository(client).fetchTopCryptos(),
        throwsA(
          isA<ServerException>().having(
            (ServerException e) => e.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
    });

    test('leve RateLimitException sur un 429 (limite CoinGecko)', () async {
      final client = _FakeHttpClient(statusCode: 429, body: 'Too Many Requests');

      await expectLater(
        MarketRepository(client).fetchTopCryptos(),
        throwsA(isA<RateLimitException>()),
      );
    });
  });

  group('fetchTopCryptos - erreurs de transport', () {
    test('leve NetworkException si le transport echoue (pas de connexion)', () async {
      final client = _FakeHttpClient(
        error: http.ClientException('Failed host lookup'),
      );

      await expectLater(
        MarketRepository(client).fetchTopCryptos(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('leve RequestTimeoutException si la reponse depasse le delai', () async {
      final client = _FakeHttpClient(
        statusCode: 200,
        body: jsonEncode(<Object>[]),
        delay: const Duration(milliseconds: 200),
      );

      await expectLater(
        MarketRepository(
          client,
          timeout: const Duration(milliseconds: 10),
        ).fetchTopCryptos(),
        throwsA(
          isA<RequestTimeoutException>().having(
            (RequestTimeoutException e) => e.timeout,
            'timeout',
            const Duration(milliseconds: 10),
          ),
        ),
      );
    });
  });

  group('fetchTopCryptos - donnees invalides', () {
    test('leve InvalidDataException si la reponse est un objet et non une liste', () async {
      final client = _FakeHttpClient(
        statusCode: 200,
        body: jsonEncode(<String, String>{'error': 'invalid response'}),
      );

      await expectLater(
        MarketRepository(client).fetchTopCryptos(),
        throwsA(isA<InvalidDataException>()),
      );
    });

    test('leve InvalidDataException si le corps est du HTML et non du JSON', () async {
      final client = _FakeHttpClient(
        statusCode: 200,
        body: '<html><body>503 Service Unavailable</body></html>',
      );

      await expectLater(
        MarketRepository(client).fetchTopCryptos(),
        throwsA(isA<InvalidDataException>()),
      );
    });

    test('ignore un item invalide et retourne les autres', () async {
      final client = _FakeHttpClient(
        statusCode: 200,
        body: jsonEncode(<Map<String, dynamic>>[
          _validEntry(
            id: 'bitcoin',
            name: 'Bitcoin',
            symbol: 'btc',
            price: 45000.0,
          ),
          _brokenEntry('cassee'),
          _validEntry(
            id: 'ethereum',
            name: 'Ethereum',
            symbol: 'eth',
            price: 3000.0,
          ),
        ]),
      );

      final cryptos = await MarketRepository(client).fetchTopCryptos();

      expect(cryptos, hasLength(2));
      expect(cryptos.map((crypto) => crypto.id), <String>['bitcoin', 'ethereum']);
    });

    test('ignore un item qui est une chaine et non un objet JSON', () async {
      final client = _FakeHttpClient(
        statusCode: 200,
        body: jsonEncode(<Object>[
          _validEntry(
            id: 'bitcoin',
            name: 'Bitcoin',
            symbol: 'btc',
            price: 45000.0,
          ),
          'pas-un-objet',
        ]),
      );

      final cryptos = await MarketRepository(client).fetchTopCryptos();

      expect(cryptos, hasLength(1));
      expect(cryptos.single.id, 'bitcoin');
    });
  });

  group('aucune erreur silencieuse', () {
    test('un item rejete laisse une trace nominative', () async {
      final trace = _TraceRecorder();
      final client = _FakeHttpClient(
        statusCode: 200,
        body: jsonEncode(<Map<String, dynamic>>[
          _validEntry(
            id: 'bitcoin',
            name: 'Bitcoin',
            symbol: 'btc',
            price: 45000.0,
          ),
          _brokenEntry('cassee'),
        ]),
      );

      final cryptos = await MarketRepository(
        client,
        log: trace.call,
      ).fetchTopCryptos();

      expect(cryptos, hasLength(1));
      expect(trace.messages, isNotEmpty, reason: 'le rejet doit etre trace');
      expect(trace.joined, contains('cassee'));
    });

    test('la trace de rejet transporte la cause', () async {
      final trace = _TraceRecorder();
      final client = _FakeHttpClient(
        statusCode: 200,
        body: jsonEncode(<Map<String, dynamic>>[
          _validEntry(
            id: 'bitcoin',
            name: 'Bitcoin',
            symbol: 'btc',
            price: 45000.0,
          ),
          _brokenEntry('cassee'),
        ]),
      );

      await MarketRepository(client, log: trace.call).fetchTopCryptos();

      expect(trace.errors.whereType<FormatException>(), isNotEmpty);
    });

    test('un rejet partiel laisse un resume chiffre', () async {
      final trace = _TraceRecorder();
      final client = _FakeHttpClient(
        statusCode: 200,
        body: jsonEncode(<Map<String, dynamic>>[
          _validEntry(
            id: 'bitcoin',
            name: 'Bitcoin',
            symbol: 'btc',
            price: 45000.0,
          ),
          _brokenEntry('a'),
          _brokenEntry('b'),
        ]),
      );

      await MarketRepository(client, log: trace.call).fetchTopCryptos();

      expect(trace.joined, contains('2'));
      expect(trace.joined, contains('3'));
    });
  });

  group('contrat rompu - changement de format CoinGecko', () {
    test('leve InvalidDataException si aucun item recu est exploitable', () async {
      final client = _FakeHttpClient(
        statusCode: 200,
        body: jsonEncode(<Map<String, dynamic>>[
          _brokenEntry('a'),
          _brokenEntry('b'),
          _brokenEntry('c'),
        ]),
      );

      await expectLater(
        MarketRepository(client).fetchTopCryptos(),
        throwsA(isA<InvalidDataException>()),
      );
    });

    test('le diagnostic du contrat rompu cite les compteurs', () async {
      final client = _FakeHttpClient(
        statusCode: 200,
        body: jsonEncode(<Map<String, dynamic>>[
          _brokenEntry('a'),
          _brokenEntry('b'),
        ]),
      );

      await expectLater(
        MarketRepository(client).fetchTopCryptos(),
        throwsA(
          isA<InvalidDataException>().having(
            (InvalidDataException e) => e.reason,
            'reason',
            allOf(contains('0'), contains('2')),
          ),
        ),
      );
    });

    test('une liste vide reste une reponse legitime, pas un contrat rompu', () async {
      final client = _FakeHttpClient(
        statusCode: 200,
        body: jsonEncode(<Object>[]),
      );

      await expectLater(MarketRepository(client).fetchTopCryptos(), completes);
    });
  });

  group('contrat du repository', () {
    test('toutes les erreurs sortent en AppException, jamais autre chose', () async {
      final clients = <_FakeHttpClient>[
        _FakeHttpClient(statusCode: 500, body: 'boom'),
        _FakeHttpClient(statusCode: 429, body: 'slow down'),
        _FakeHttpClient(error: http.ClientException('offline')),
        _FakeHttpClient(statusCode: 200, body: 'pas du json'),
        _FakeHttpClient(
          statusCode: 200,
          body: jsonEncode(<String, int>{'a': 1}),
        ),
      ];

      for (final client in clients) {
        await expectLater(
          MarketRepository(client).fetchTopCryptos(),
          throwsA(isA<AppException>()),
        );
      }
    });
  });
}
