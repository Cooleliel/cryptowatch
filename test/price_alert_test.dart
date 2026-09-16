import 'package:flutter_test/flutter_test.dart';

import 'package:cryptowatch/features/alerts/domain/price_alert.dart';

PriceAlert _alert({
  double threshold = 50000,
  AlertCondition condition = AlertCondition.above,
  bool active = true,
  DateTime? lastTriggeredAt,
}) => PriceAlert(
  id: '1',
  cryptoId: 'bitcoin',
  cryptoSymbol: 'btc',
  cryptoName: 'Bitcoin',
  threshold: threshold,
  condition: condition,
  active: active,
  lastTriggeredAt: lastTriggeredAt,
);

void main() {
  group('matches', () {
    test('above : vrai au seuil et au-dessus, faux en dessous', () {
      final alert = _alert(threshold: 50000);
      expect(alert.matches(50000), isTrue);
      expect(alert.matches(50000.01), isTrue);
      expect(alert.matches(49999.99), isFalse);
    });

    test('below : vrai au seuil et en dessous, faux au-dessus', () {
      final alert = _alert(threshold: 40000, condition: AlertCondition.below);
      expect(alert.matches(40000), isTrue);
      expect(alert.matches(39999.99), isTrue);
      expect(alert.matches(40000.01), isFalse);
    });
  });

  group('cooldown', () {
    final now = DateTime(2026, 9, 15, 12, 0);

    test('jamais déclenchée : peut déclencher', () {
      expect(_alert().canTriggerAgainAt(now), isTrue);
    });

    test('déclenchée il y a moins que le cooldown : bloquée', () {
      final alert = _alert(
        lastTriggeredAt: now.subtract(const Duration(minutes: 2)),
      );
      expect(alert.canTriggerAgainAt(now), isFalse);
    });

    test('déclenchée il y a exactement le cooldown : débloquée', () {
      final alert = _alert(lastTriggeredAt: now.subtract(PriceAlert.cooldown));
      expect(alert.canTriggerAgainAt(now), isTrue);
    });
  });

  test('AlertTriggeredEvent.message décrit le franchissement', () {
    const event = AlertTriggeredEvent(
      cryptoName: 'Bitcoin',
      price: 50100,
      condition: AlertCondition.above,
      threshold: 50000,
    );
    expect(event.message, contains('Bitcoin'));
    expect(event.message, contains('dépassé'));
    expect(event.message, contains('50000.00'));
  });
}
