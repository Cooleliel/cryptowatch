import 'dart:developer' as developer;

/// Signature d'une trace applicative.
///
/// Volontairement une fonction et non une classe : c'est injectable avec une
/// valeur par defaut, donc aucun appelant existant ne casse, et un test peut
/// capturer les traces pour PROUVER qu'une erreur n'est pas silencieuse.
///
/// Regle d'equipe : tout `catch` qui n'aboutit pas a une exception relancee
/// DOIT appeler un [AppLog]. Une erreur avalee sans trace est un bug qu'on ne
/// pourra pas diagnostiquer en demo.
typedef AppLog =
    void Function(String message, {Object? error, StackTrace? stackTrace});

/// Implementation par defaut : visible dans la console et dans DevTools.
///
/// Passe par `dart:developer` plutot que `print` : les traces sont taguees,
/// filtrables, et `print` est interdit par flutter_lints en production.
void defaultAppLog(String message, {Object? error, StackTrace? stackTrace}) {
  developer.log(
    message,
    name: 'cryptowatch',
    error: error,
    stackTrace: stackTrace,
  );
}
