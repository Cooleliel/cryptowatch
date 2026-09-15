import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cryptowatch/features/alerts/data/alerts_repository.dart';
import 'package:cryptowatch/features/alerts/domain/price_alert.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';
import 'package:cryptowatch/shared/notifications/notification_service.dart';

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepository();
});

/// Résultat pur d'une vérification de seuils : pas d'effet de bord sur
/// [state] ici, pour pouvoir être utilisé aussi bien dans [build] (où
/// [state] n'existe pas encore) que dans le listener temps réel.
class _ThresholdCheckResult {
  const _ThresholdCheckResult(this.alerts, this.changed);
  final List<PriceAlert> alerts;
  final bool changed;
}

class AlertsNotifier extends AsyncNotifier<List<PriceAlert>> {
  @override
  Future<List<PriceAlert>> build() async {
    // Couvre les mises à jour FUTURES du marché (tick suivant, retry...).
    ref.listen<AsyncValue<List<Crypto>>>(marketProvider, (previous, next) {
      next.whenData(_checkThresholds);
    });

    final loadedAlerts = await ref.read(alertsRepositoryProvider).loadAlerts();

    // Le ref.listen ci-dessus ne réagit qu'aux changements après cet
    // abonnement : si marketProvider a déjà fini de charger pendant qu'on
    // attendait loadAlerts(), sa transition a pu être manquée (state
    // n'existait pas encore côté AlertsNotifier à ce moment-là). On
    // vérifie donc explicitement une fois avec l'état de marché déjà
    // disponible, pour ne jamais rater le premier passage.
    final currentMarket = ref.read(marketProvider).value;
    if (currentMarket == null) return loadedAlerts;

    final result = _evaluateThresholds(loadedAlerts, currentMarket);
    if (result.changed) {
      // Persistance en tâche de fond : ne bloque pas la résolution de
      // build() pour un side-effect qui peut se faire après coup.
      unawaited(ref.read(alertsRepositoryProvider).saveAlerts(result.alerts));
    }
    return result.alerts;
  }

  Future<void> _persist() async {
    final alerts = state.value;
    if (alerts == null) return;
    await ref.read(alertsRepositoryProvider).saveAlerts(alerts);
  }

  /// Calcul pur : compare chaque alerte active à la crypto correspondante,
  /// déclenche la notification pour celles qui franchissent leur seuil
  /// (et dont le cooldown est écoulé), sans toucher à [state].
  _ThresholdCheckResult _evaluateThresholds(
    List<PriceAlert> alerts,
    List<Crypto> cryptos,
  ) {
    var changed = false;
    final updatedAlerts = <PriceAlert>[];

    for (final alert in alerts) {
      if (!alert.active) {
        updatedAlerts.add(alert);
        continue;
      }

      final matches = cryptos.where((c) => c.symbol == alert.cryptoSymbol);
      if (matches.isEmpty) {
        updatedAlerts.add(alert);
        continue;
      }

      final currentPrice = matches.first.currentPrice;
      if (alert.matches(currentPrice) && alert.canTriggerAgain) {
        ref.read(notificationServiceProvider).showPriceAlert(
              cryptoName: matches.first.name,
              price: currentPrice,
              condition: alert.condition,
              threshold: alert.threshold,
            );
        updatedAlerts.add(alert.copyWith(lastTriggeredAt: DateTime.now()));
        changed = true;
      } else {
        updatedAlerts.add(alert);
      }
    }

    return _ThresholdCheckResult(updatedAlerts, changed);
  }

  /// Utilisé par le listener temps réel : lit/écrit [state], contrairement
  /// à [_evaluateThresholds] qui reste pur et réutilisable dans [build].
  void _checkThresholds(List<Crypto> cryptos) {
    final alerts = state.value;
    if (alerts == null || alerts.isEmpty) return;

    final result = _evaluateThresholds(alerts, cryptos);
    if (result.changed) {
      state = AsyncData(result.alerts);
      _persist();
    }
  }

  Future<void> addAlert(PriceAlert alert) async {
    final current = state.value ?? [];
    state = AsyncData([...current, alert]);
    await _persist();
  }

  Future<void> removeAlert(String id) async {
    final current = state.value ?? [];
    state = AsyncData(current.where((a) => a.id != id).toList());
    await _persist();
  }

  Future<void> toggleActive(String id) async {
    final current = state.value ?? [];
    state = AsyncData([
      for (final a in current)
        if (a.id == id) a.copyWith(active: !a.active) else a,
    ]);
    await _persist();
  }
}

final alertsProvider = AsyncNotifierProvider<AlertsNotifier, List<PriceAlert>>(
  AlertsNotifier.new,
);