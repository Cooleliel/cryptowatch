import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:cryptowatch/features/crypto_detail/data/repositories/price_history_repository.dart';

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
  Uri? requestedUri;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestedUri = request.url;
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      statusCode,
    );
  }
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

    final points = await PriceHistoryRepository(client).fetchLast7Days('bitcoin');

    expect(points, hasLength(2));
    expect(points.first.price, 64000.12);
    expect(
      points.first.time,
      DateTime.fromMillisecondsSinceEpoch(1725600000000),
    );
    expect(points.last.price, 65100.0);
    expect(client.requestedUri.toString(), contains('/coins/bitcoin/market_chart'));
    expect(client.requestedUri.toString(), contains('days=7'));
    expect(client.requestedUri.toString(), contains('vs_currency=usd'));
  });

  test('fetchLast7Days lève une erreur si la réponse HTTP échoue', () async {
    final client = _FakeHttpClient(statusCode: 500, body: 'Server error');

    expect(
      () => PriceHistoryRepository(client).fetchLast7Days('bitcoin'),
      throwsException,
    );
  });

  test("fetchLast7Days lève une FormatException si le JSON n'est pas un objet",
      () async {
    final client = _FakeHttpClient(
      statusCode: 200,
      body: jsonEncode(['pas', 'un', 'objet']),
    );

    expect(
      () => PriceHistoryRepository(client).fetchLast7Days('ethereum'),
      throwsFormatException,
    );
  });

  test("fetchLast7Days lève une FormatException si prices n'est pas une liste",
      () async {
    final client = _FakeHttpClient(
      statusCode: 200,
      body: jsonEncode({'prices': 'invalide'}),
    );

    expect(
      () => PriceHistoryRepository(client).fetchLast7Days('bitcoin'),
      throwsFormatException,
    );
  });
}
