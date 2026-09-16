/// Sens du franchissement surveillé.
enum AlertCondition { above, below }

/// Une alerte de prix (T-13a). Dart pur, aucune dépendance.
///
/// Vit le temps de la session, comme la surveillance qui la sert : sans
/// service d'arrière-plan, une alerte persistée ne pourrait de toute façon
/// pas fonctionner app fermée (voir README, section Évolutions).
class PriceAlert {
  const PriceAlert({
    required this.id,
    required this.cryptoId,
    required this.cryptoSymbol,
    required this.cryptoName,
    required this.threshold,
    required this.condition,
    this.active = true,
    this.lastTriggeredAt,
  });

  final String id;
  final String cryptoId;
  final String cryptoSymbol;
  final String cryptoName;
  final double threshold;
  final AlertCondition condition;
  final bool active;

  /// Dernier déclenchement. `null` : jamais déclenchée. Sert au cooldown.
  final DateTime? lastTriggeredAt;

  /// Anti-martèlement : un prix qui oscille autour du seuil au rythme des
  /// ticks Binance (~1/s) déclencherait sinon des dizaines d'alertes par
  /// minute — le frère du backoff de T-07.
  static const Duration cooldown = Duration(minutes: 5);

  bool matches(double currentPrice) => condition == AlertCondition.above
      ? currentPrice >= threshold
      : currentPrice <= threshold;

  bool canTriggerAgainAt(DateTime now) {
    final last = lastTriggeredAt;
    if (last == null) return true;
    return now.difference(last) >= cooldown;
  }

  PriceAlert copyWith({bool? active, DateTime? lastTriggeredAt}) {
    return PriceAlert(
      id: id,
      cryptoId: cryptoId,
      cryptoSymbol: cryptoSymbol,
      cryptoName: cryptoName,
      threshold: threshold,
      condition: condition,
      active: active ?? this.active,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
    );
  }
}

/// Événement émis quand une alerte se déclenche - ce que l'UI affichera.
class AlertTriggeredEvent {
  const AlertTriggeredEvent({
    required this.cryptoName,
    required this.price,
    required this.condition,
    required this.threshold,
  });

  final String cryptoName;
  final double price;
  final AlertCondition condition;
  final double threshold;

  String get message {
    final direction = condition == AlertCondition.above
        ? 'a dépassé'
        : 'est passé sous';
    return '$cryptoName $direction ${threshold.toStringAsFixed(2)} \$ '
        '(actuellement ${price.toStringAsFixed(2)} \$)';
  }
}
