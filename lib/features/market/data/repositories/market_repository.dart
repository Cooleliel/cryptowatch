import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/shared/errors/app_exception.dart';
import 'package:cryptowatch/shared/logging/app_logger.dart';

/// Acces aux donnees de marche de CoinGecko.
///
/// Contrat : `fetchTopCryptos` ne laisse sortir que des [AppException].
/// Aucune erreur brute de `package:http` ou de `dart:convert` n'atteint la
/// couche presentation, qui peut donc traiter les pannes par un `switch`
/// exhaustif sans jamais recevoir de surprise.
///
/// Contrat de tracage : aucun element rejete ne disparait en silence.
class MarketRepository {
  static const _topCryptosUrl =
      'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=50&page=1';

  /// Delai au-dela duquel la requete est abandonnee.
  ///
  /// Injectable pour que les tests n'aient pas a patienter dix secondes.
  static const Duration _defaultTimeout = Duration(seconds: 10);

  MarketRepository(
    this._client, {
    this.timeout = _defaultTimeout,
    this.log = defaultAppLog,
  });

  final http.Client _client;

  /// Delai effectivement applique aux requetes de ce repository.
  final Duration timeout;

  /// Ou partent les traces. Injectable pour que les tests puissent verifier
  /// qu'un rejet laisse bien une trace.
  final AppLog log;

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
  /// depassements de delai en [AppException].
  Future<http.Response> _get(Uri uri) async {
    try {
      return await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw RequestTimeoutException(timeout);
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
  /// l'utilisateur de tout le marche. Mais chaque rejet laisse une trace, et
  /// si PLUS AUCUNE entree n'est exploitable, c'est que le format de l'API a
  /// change - on leve alors plutot que de renvoyer une liste vide qui
  /// s'afficherait comme un marche desert sans explication.
  List<Crypto> _parseCryptos(List<Object?> items) {
    final List<Crypto> cryptos = <Crypto>[];

    for (final Object? item in items) {
      if (item is! Map<String, dynamic>) {
        log('Entree CoinGecko ignoree : ce n\'est pas un objet JSON');
        continue;
      }
      try {
        cryptos.add(Crypto.fromCoinGeckoJson(item));
      } on FormatException catch (error, stackTrace) {
        log(
          'Entree CoinGecko ignoree (id=${item['id'] ?? 'inconnu'})',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    final int rejected = items.length - cryptos.length;

    if (items.isNotEmpty && cryptos.isEmpty) {
      throw InvalidDataException(
        '0 item exploitable sur ${items.length} : '
        'le format CoinGecko a probablement change',
      );
    }

    if (rejected > 0) {
      log('$rejected entree(s) ignoree(s) sur ${items.length}');
    }

    return cryptos;
  }
}
