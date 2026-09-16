import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cryptowatch/features/alerts/domain/price_alert.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Le dernier événement d'alerte déclenchée. AppShell l'écoute pour
/// afficher la SnackBar, où que soit l'utilisateur dans l'app.
final alertEventProvider = StateProvider<AlertTriggeredEvent?>((ref) => null);

/// Horloge injectable : les tests du cooldown pilotent le temps.
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Les alertes de la session (T-13a) et leur surveillance du marché.
///
/// Surveillance : le notifier observe [marketProvider], déjà vivant grâce à
/// T-07/T-08a — chaque tick Binance passe par ici. Une alerte n'est qu'un
/// consommateur de plus du flux existant.
class AlertsNotifier extends Notifier<List<PriceAlert>> {
  @override
  List<PriceAlert> build() {
    ref.listen<AsyncValue<List<Crypto>>>(
      marketProvider,
      (previous, next) => next.whenData(_checkThresholds),
    );
    return const [];
  }

  void _checkThresholds(List<Crypto> cryptos) {
    if (state.isEmpty) return;
    final now = ref.read(nowProvider)();

    var changed = false;
    final updated = <PriceAlert>[];

    for (final alert in state) {
      if (!alert.active) {
        updated.add(alert);
        continue;
      }
      final matches = cryptos.where((c) => c.symbol == alert.cryptoSymbol);
      if (matches.isEmpty) {
        updated.add(alert);
        continue;
      }
      final price = matches.first.currentPrice;
      if (alert.matches(price) && alert.canTriggerAgainAt(now)) {
        ref.read(alertEventProvider.notifier).state = AlertTriggeredEvent(
          cryptoName: alert.cryptoName,
          price: price,
          condition: alert.condition,
          threshold: alert.threshold,
        );
        updated.add(alert.copyWith(lastTriggeredAt: now));
        changed = true;
      } else {
        updated.add(alert);
      }
    }

    if (changed) state = updated;
  }

  void addAlert(PriceAlert alert) => state = [...state, alert];

  void removeAlert(String id) =>
      state = state.where((a) => a.id != id).toList();

  void toggleActive(String id) => state = [
    for (final a in state)
      if (a.id == id) a.copyWith(active: !a.active) else a,
  ];
}

final alertsProvider = NotifierProvider<AlertsNotifier, List<PriceAlert>>(
  AlertsNotifier.new,
);
