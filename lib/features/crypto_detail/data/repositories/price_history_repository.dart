import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:cryptowatch/features/crypto_detail/domain/price_point.dart';
import 'package:cryptowatch/shared/errors/app_exception.dart';
import 'package:cryptowatch/shared/logging/app_logger.dart';

/// T-10a : historique 7 jours depuis CoinGecko `/coins/{id}/market_chart`.
///
/// Contrat identique à [MarketRepository] : seules des [AppException]
/// sortent de [fetchLast7Days], et aucun point rejeté ne disparaît en silence.
class PriceHistoryRepository {
  static const Duration _defaultTimeout = Duration(seconds: 10);

  PriceHistoryRepository(
    this._client, {
    this.timeout = _defaultTimeout,
    this.log = defaultAppLog,
  });

  final http.Client _client;
  final Duration timeout;

  /// Où partent les traces. Injectable pour que les tests puissent
  /// vérifier qu'un rejet laisse bien une trace.
  final AppLog log;

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
  ///
  /// Mais chaque rejet laisse une trace, et si plus AUCUN point n'est
  /// exploitable, c'est que le format de l'API a changé : on lève plutôt que
  /// de renvoyer une courbe vide que personne ne saurait expliquer.
  List<PricePoint> _parsePoints(List<Object?> items) {
    final points = <PricePoint>[];
    for (final item in items) {
      if (item is! List) {
        log('Point de prix ignoré : pas une paire [instant, prix]');
        continue;
      }
      try {
        points.add(PricePoint.fromCoinGeckoPair(item));
      } on FormatException catch (error, stackTrace) {
        log('Point de prix ignoré', error: error, stackTrace: stackTrace);
      }
    }

    final rejected = items.length - points.length;

    if (items.isNotEmpty && points.isEmpty) {
      throw InvalidDataException(
        '0 point exploitable sur ${items.length} : '
        'le format CoinGecko a probablement changé',
      );
    }

    if (rejected > 0) {
      log('$rejected point(s) ignoré(s) sur ${items.length}');
    }

    return points;
  }
}
