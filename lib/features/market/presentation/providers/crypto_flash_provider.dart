import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

/// État du flash visuel d'une carte crypto après une mise à jour de prix.
///
/// [up]   → le prix a augmenté depuis le tick précédent → fond vert.
/// [down] → le prix a diminué                          → fond rouge.
/// [none] → état neutre (chargement initial ou flash éteint).
enum FlashState { none, up, down }

/// Durée pendant laquelle le fond coloré reste visible.
///
/// 600 ms : perceptible à l'œil sans gêner si les ticks arrivent vite
/// (Binance envoie environ 1 tick/s par paire). La valeur est exposée
/// publiquement pour que les tests puissent l'injecter sans la dupliquer.
const flashDuration = Duration(milliseconds: 600);

/// Notifier qui gère l'état flash d'une seule crypto (identifiée par symbole).
///
/// Cycle de vie :
///   1. [trigger] compare le nouveau prix à l'ancien et détermine [up]/[down].
///   2. Un timer lancé sur [flashDuration] repasse l'état à [none].
///   3. Si [trigger] est rappelé avant l'extinction, l'ancien timer est annulé
///      et un nouveau part, ce qui re-déclenche le flash proprement.
///
/// **Choix : `StateNotifier` plutôt que `Notifier`.**
///
/// Le projet utilise déjà `StateNotifier` (ex : `PriceHistoryNotifier`,
/// `MarketFilterNotifier`) avec le pattern
/// `StateNotifierProvider.autoDispose.family`. On suit ce pattern pour rester
/// cohérent avec les conventions établies, plutôt que d'introduire `Notifier`
/// (Riverpod 2+) qui a des contraintes différentes sur les family providers.
///
/// **Pourquoi auto-dispose ?**
/// Quand une carte sort de l'écran (scroll hors vue), Riverpod détruit le
/// provider et le timer avec, évitant une fuite mémoire.
class CryptoFlashNotifier extends StateNotifier<FlashState> {
  CryptoFlashNotifier() : super(FlashState.none);

  Timer? _timer;

  /// Prix mémorisé lors du dernier tick, pour comparer avec le suivant.
  ///
  /// `null` au premier tick : pas de flash pour éviter un fond coloré
  /// parasite à l'ouverture de l'écran (le prix initial n'est pas une
  /// variation, c'est juste le chargement).
  double? _previousPrice;

  /// Reçoit le nouveau prix, détermine la direction du flash et
  /// programme l'extinction automatique.
  ///
  /// Sans effet si [newPrice] est identique au prix précédent
  /// (tick Binance sans changement réel).
  void trigger(double newPrice) {
    final prev = _previousPrice;
    _previousPrice = newPrice;

    // Premier tick : on mémorise le prix de départ sans afficher de flash.
    if (prev == null) return;

    // Aucun changement : on ne relance pas le timer pour rien.
    if (newPrice == prev) return;

    final direction = newPrice > prev ? FlashState.up : FlashState.down;

    // Annule le timer précédent s'il était encore en cours, ce qui permet
    // de re-déclencher proprement un flash si deux ticks arrivent
    // dans la même fenêtre de 600 ms.
    _timer?.cancel();
    state = direction;

    _timer = Timer(flashDuration, () {
      // Vérifie que le notifier est encore monté avant d'écrire.
      if (mounted) state = FlashState.none;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provider par symbole (family).
///
/// Chaque carte crypto observe uniquement sa propre instance : seule la carte
/// dont le prix change redessine. Sans ce découpage par symbole, une mise à
/// jour d'une seule crypto forcerait le rebuild de toutes les cartes de la
/// liste — le problème de performance que T-08b est chargé de régler.
///
/// Chaque instance est auto-disposée quand plus aucun widget ne l'observe,
/// ce qui libère le timer associé et évite les fuites mémoire lors du scroll.
final cryptoFlashProvider = StateNotifierProvider.autoDispose
    .family<CryptoFlashNotifier, FlashState, String>(
  (ref, symbol) => CryptoFlashNotifier(),
);
