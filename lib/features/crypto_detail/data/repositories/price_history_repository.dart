import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:cryptowatch/features/crypto_detail/domain/price_point.dart';

/// T-10a : historique 7 jours depuis CoinGecko `/coins/{id}/market_chart`.
class PriceHistoryRepository {
  PriceHistoryRepository(this._client);

  final http.Client _client;

  Future<List<PricePoint>> fetchLast7Days(String coinId) async {
    final uri = Uri.https(
      'api.coingecko.com',
      '/api/v3/coins/$coinId/market_chart',
      {'vs_currency': 'usd', 'days': '7'},
    );

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch 7-day price history');
    }

    final decodedJson = jsonDecode(response.body);
    if (decodedJson is! Map<String, dynamic>) {
      throw const FormatException('Expected a market_chart object');
    }

    final prices = decodedJson['prices'];
    if (prices is! List) {
      throw const FormatException('Expected a list of prices');
    }

    return prices.map((item) {
      if (item is! List) {
        throw const FormatException('Expected a [timestamp, price] pair');
      }
      return PricePoint.fromCoinGeckoPair(item);
    }).toList();
  }
}
