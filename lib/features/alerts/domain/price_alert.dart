enum AlertCondition { above, below }

class PriceAlert {
  const PriceAlert({
    required this.id,
    required this.cryptoId,
    required this.cryptoSymbol,
    required this.threshold,
    required this.condition,
    this.active = true,
    this.lastTriggeredAt,
  });

  final String id;
  final String cryptoId;      // ex: "bitcoin" — pour retrouver le nom/logo
  final String cryptoSymbol;  // ex: "btc" — pour matcher avec Crypto.symbol
  final double threshold;
  final AlertCondition condition;
  final bool active;

  /// Dernière fois que cette alerte a déclenché une notification.
  /// `null` : jamais déclenchée. Sert au cooldown de 20 min.
  final DateTime? lastTriggeredAt;

  bool get isTriggered => condition == AlertCondition.above;

  bool matches(double currentPrice) {
    return condition == AlertCondition.above
        ? currentPrice >= threshold
        : currentPrice <= threshold;
  }

  /// Vrai si le cooldown de 20 min est écoulé (ou jamais déclenchée).
  bool get canTriggerAgain {
    if (lastTriggeredAt == null) return true;
    return DateTime.now().difference(lastTriggeredAt!) >=
        const Duration(minutes: 20);
  }

  PriceAlert copyWith({
    bool? active,
    DateTime? lastTriggeredAt,
  }) {
    return PriceAlert(
      id: id,
      cryptoId: cryptoId,
      cryptoSymbol: cryptoSymbol,
      threshold: threshold,
      condition: condition,
      active: active ?? this.active,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
    );
  }

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      id: json['id'] as String,
      cryptoId: json['cryptoId'] as String,
      cryptoSymbol: json['cryptoSymbol'] as String,
      threshold: (json['threshold'] as num).toDouble(),
      condition: AlertCondition.values.byName(json['condition'] as String),
      active: json['active'] as bool? ?? true,
      lastTriggeredAt: json['lastTriggeredAt'] != null
          ? DateTime.tryParse(json['lastTriggeredAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cryptoId': cryptoId,
        'cryptoSymbol': cryptoSymbol,
        'threshold': threshold,
        'condition': condition.name,
        'active': active,
        'lastTriggeredAt': lastTriggeredAt?.toIso8601String(),
      };
}