import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';

import 'package:cryptowatch/features/market/data/repositories/market_repository.dart';

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
  test('fetchTopCryptos retourne les cryptos de CoinGecko', () async {
    final client = _FakeHttpClient(
      statusCode: 200,
      body: jsonEncode([
        {
          'id': 'bitcoin',
          'name': 'Bitcoin',
          'symbol': 'btc',
          'current_price': 45000.0,
        },
        {
          'id': 'ethereum',
          'name': 'Ethereum',
          'symbol': 'eth',
          'current_price': 3000.0,
        },
      ]),
    );

    final cryptos = await MarketRepository(client).fetchTopCryptos();

    expect(cryptos, hasLength(2));
    expect(cryptos.first.name, 'Bitcoin');
    expect(cryptos.first.currentPrice, 45000.0);
    expect(client.requestedUri.toString(), contains('/coins/markets'));
  });

  test('fetchTopCryptos lève une erreur si la réponse HTTP échoue', () async {
    final client = _FakeHttpClient(statusCode: 500, body: 'Server error');

    expect(
      () => MarketRepository(client).fetchTopCryptos(),
      throwsException,
    );
  });

  test("fetchTopCryptos leve une erreur si la reponse n'est pas une liste", () async {
    final client = _FakeHttpClient(
      statusCode: 200,
      body: jsonEncode({'error': 'invalid response'}),
    );

    expect(
      () => MarketRepository(client).fetchTopCryptos(),
      throwsFormatException,
    );
  });
}