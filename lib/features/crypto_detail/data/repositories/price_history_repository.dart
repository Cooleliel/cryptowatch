import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:cryptowatch/features/crypto_detail/domain/price_point.dart';
import 'package:cryptowatch/features/market/data/market_exception.dart';

/// T-10a : historique 7 jours depuis CoinGecko `/coins/{id}/market_chart`.
///
/// Contrat identique à [MarketRepository] : seules des [MarketException]
/// sortent de [fetchLast7Days].
class PriceHistoryRepository {
  static const Duration _defaultTimeout = Duration(seconds: 10);

  PriceHistoryRepository(this._client, {this.timeout = _defaultTimeout});

  final http.Client _client;
  final Duration timeout;

  Future<List<PricePoint>> fetchLast7Days(String coinId) async {
    final uri = Uri.https(
      'api.coingecko.com',
      '/api/v3/coins/$coinId/market_chart',
      {'vs_currency': 'usd', 'days': '7'},
    );

    final response = await _get(uri);

    if (response.statusCode == 429) {
      throw const RateLimitException();
    }
    if (response.statusCode != 200) {
      throw ServerException(response.statusCode);
    }

    final decodedJson = _decodeBody(response.body);
    if (decodedJson is! Map<String, dynamic>) {
      throw const InvalidDataException("la reponse JSON n'est pas un objet");
    }

    final prices = decodedJson['prices'];
    if (prices is! List) {
      throw const InvalidDataException("la reponse JSON n'a pas de liste prices");
    }

    return _parsePoints(prices);
  }

  Future<http.Response> _get(Uri uri) async {
    try {
      return await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw RequestTimeoutException(timeout);
    } on http.ClientException catch (error) {
      throw NetworkException(error);
    }
  }

  Object? _decodeBody(String body) {
    try {
      return jsonDecode(body);
    } on FormatException catch (error) {
      throw InvalidDataException('corps illisible : ${error.message}');
    }
  }

  /// Ignore un point casse : un timestamp pourri ne doit pas tuer toute la courbe.
  List<PricePoint> _parsePoints(List<Object?> items) {
    final points = <PricePoint>[];
    for (final item in items) {
      if (item is! List) continue;
      try {
        points.add(PricePoint.fromCoinGeckoPair(item));
      } on FormatException {
        continue;
      }
    }
    return points;
  }
}
