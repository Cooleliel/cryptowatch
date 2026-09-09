import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:cryptowatch/features/market/data/market_exception.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';

/// Acces aux donnees de marche de CoinGecko.
///
/// Contrat : `fetchTopCryptos` ne laisse sortir que des [MarketException].
/// Aucune erreur brute de `package:http` ou de `dart:convert` n'atteint la
/// couche presentation, qui peut donc traiter les pannes par un `switch`
/// exhaustif sans jamais recevoir de surprise.
class MarketRepository {
  static const _topCryptosUrl =
      'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=50&page=1';

  /// Delai au-dela duquel la requete est abandonnee.
  ///
  /// Injectable pour que les tests n'aient pas a patienter dix secondes.
  static const Duration _defaultTimeout = Duration(seconds: 10);

  MarketRepository(this._client, {Duration timeout = _defaultTimeout})
    : _timeout = timeout;

  final http.Client _client;
  final Duration _timeout;

  Future<List<Crypto>> fetchTopCryptos() async {
    final http.Response response = await _get(Uri.parse(_topCryptosUrl));

    // 429 est distingue des autres erreurs serveur : CoinGecko limite a
    // ~30 appels/min sans cle, et la bonne reaction est de ralentir.
    if (response.statusCode == 429) {
      throw const RateLimitException();
    }
    if (response.statusCode != 200) {
      throw ServerException(response.statusCode);
    }

    final Object? decodedJson = _decodeBody(response.body);
    if (decodedJson is! List) {
      throw const InvalidDataException("la reponse JSON n'est pas une liste");
    }

    return _parseCryptos(decodedJson);
  }

  /// Execute la requete en convertissant les pannes de transport et les
  /// depassements de delai en [MarketException].
  Future<http.Response> _get(Uri uri) async {
    try {
      return await _client.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw RequestTimeoutException(_timeout);
    } on http.ClientException catch (error) {
      // IOClient enveloppe SocketException dans ClientException : attraper
      // ClientException suffit, et evite d'importer dart:io - qui casserait
      // la compilation web du projet.
      throw NetworkException(error);
    }
  }

  Object? _decodeBody(String body) {
    try {
      return jsonDecode(body);
    } on FormatException catch (error) {
      // Arrive quand une passerelle renvoie une page HTML d'erreur avec un
      // code 200.
      throw InvalidDataException('corps illisible : ${error.message}');
    }
  }

  /// Convertit les entrees en [Crypto], en ignorant celles qui sont invalides.
  ///
  /// Choix d'equipe : une seule crypto aux donnees cassees ne doit pas priver
  /// l'utilisateur de tout le marche.
  List<Crypto> _parseCryptos(List<Object?> items) {
    final List<Crypto> cryptos = <Crypto>[];

    for (final Object? item in items) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      try {
        cryptos.add(Crypto.fromCoinGeckoJson(item));
      } on FormatException {
        continue;
      }
    }

    return cryptos;
  }
}
