/// Les erreurs que la couche `data` du marche est autorisee a laisser sortir.
///
/// Volontairement sans texte destine a l'utilisateur : une exception porte le
/// TYPE de panne et ses donnees (code HTTP, delai...), jamais la phrase
/// affichee. C'est la couche `presentation` qui choisit le message, comme
/// l'impose la regle du README (`data` ne connait pas `presentation`).
///
/// La hierarchie est `sealed` : un `switch` sur une [MarketException] cote UI
/// est verifie par l'analyseur, donc ajouter un cas ici signale aussitot les
/// ecrans a mettre a jour.
sealed class MarketException implements Exception {
  const MarketException();
}

/// Le transport a echoue avant toute reponse : pas de connexion, DNS
/// introuvable, connexion coupee en cours de route.
final class NetworkException extends MarketException {
  const NetworkException(this.cause);

  /// L'erreur d'origine, conservee pour les logs et le diagnostic.
  final Object cause;
}

/// La reponse n'est pas arrivee dans le delai imparti.
final class RequestTimeoutException extends MarketException {
  const RequestTimeoutException(this.timeout);

  /// Le delai qui a ete depasse.
  final Duration timeout;
}

/// HTTP 429 : la limite de CoinGecko (~30 appels/min sans cle) est atteinte.
///
/// Cas distinct de [ServerException] car la reaction attendue n'est pas la
/// meme : ici il faut ralentir, pas reessayer immediatement.
final class RateLimitException extends MarketException {
  const RateLimitException();
}

/// Toute autre reponse HTTP dont le code n'est pas 200.
final class ServerException extends MarketException {
  const ServerException(this.statusCode);

  final int statusCode;
}

/// La reponse est arrivee mais son contenu est inexploitable : corps qui n'est
/// pas du JSON, ou JSON qui n'est pas la liste attendue.
final class InvalidDataException extends MarketException {
  const InvalidDataException(this.reason);

  /// Ce qui n'allait pas, pour les logs (pas pour l'affichage).
  final String reason;
}
