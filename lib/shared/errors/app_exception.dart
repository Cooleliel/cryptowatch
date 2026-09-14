/// Les erreurs que la couche `data` est autorisee a laisser sortir,
/// pour TOUTES les features (market, crypto_detail, watchlist...).
///
/// Deux regles a retenir avant d'en ajouter une :
///
/// 1. **Aucun texte destine a l'utilisateur.** Une exception porte le TYPE de
///    panne et ses donnees (code HTTP, delai, diagnostic technique), jamais la
///    phrase affichee. C'est la couche `presentation` qui choisit le message
///    francais - `data` ne connait pas `presentation` (README section 3).
///
/// 2. **Tout nouveau sous-type se declare DANS CE FICHIER.** En Dart, une
///    classe `sealed` ne peut etre etendue que dans sa propre bibliotheque.
///    Ce n'est pas une contrainte subie : c'est ce qui permet a l'analyseur de
///    verifier qu'un `switch` sur une [AppException] traite bien tous les cas.
///    Ajoutez un cas ici, et tous les ecrans qui l'oublient seront signales
///    immediatement. Un oubli devient impossible a merger.
sealed class AppException implements Exception {
  const AppException();
}

/// Le transport a echoue avant toute reponse : pas de connexion, DNS
/// introuvable, connexion coupee en cours de route.
final class NetworkException extends AppException {
  const NetworkException(this.cause);

  /// L'erreur d'origine, conservee pour les logs et le diagnostic.
  final Object cause;

  @override
  String toString() => 'NetworkException($cause)';
}

/// La reponse n'est pas arrivee dans le delai imparti.
final class RequestTimeoutException extends AppException {
  const RequestTimeoutException(this.timeout);

  /// Le delai qui a ete depasse.
  final Duration timeout;

  @override
  String toString() => 'RequestTimeoutException(${timeout.inMilliseconds}ms)';
}

/// HTTP 429 : la limite de CoinGecko (~30 appels/min sans cle) est atteinte.
///
/// Cas distinct de [ServerException] car la reaction attendue n'est pas la
/// meme : ici il faut ralentir, pas reessayer immediatement.
final class RateLimitException extends AppException {
  const RateLimitException();

  @override
  String toString() => 'RateLimitException()';
}

/// Toute autre reponse HTTP dont le code n'est pas 200.
final class ServerException extends AppException {
  const ServerException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'ServerException($statusCode)';
}

/// La reponse est arrivee mais son contenu est inexploitable : corps qui n'est
/// pas du JSON, structure inattendue, ou plus aucun element lisible - signe
/// que le format de l'API a change.
final class InvalidDataException extends AppException {
  const InvalidDataException(this.reason);

  /// Ce qui n'allait pas, pour les logs et le diagnostic (pas pour l'affichage).
  final String reason;

  @override
  String toString() => 'InvalidDataException($reason)';
}
