import 'package:flutter_test/flutter_test.dart';

import 'package:cryptowatch/features/alerts/domain/price_alert.dart';

void main() {
  group('PriceAlert.matches', () {
    test('condition above : vrai si le prix atteint ou dépasse le seuil', () {
      const alert = PriceAlert(
        id: '1',
        cryptoId: 'bitcoin',
        cryptoSymbol: 'btc',
        threshold: 50000,
        condition: AlertCondition.above,
      );

      expect(alert.matches(50000), true); // égalité incluse
      expect(alert.matches(50001), true);
      expect(alert.matches(49999), false);
    });

    test('condition below : vrai si le prix atteint ou descend sous le seuil', () {
      const alert = PriceAlert(
        id: '1',
        cryptoId: 'bitcoin',
        cryptoSymbol: 'btc',
        threshold: 40000,
        condition: AlertCondition.below,
      );

      expect(alert.matches(40000), true);
      expect(alert.matches(39999), true);
      expect(alert.matches(40001), false);
    });
  });

  group('PriceAlert.canTriggerAgain (cooldown 20 min)', () {
    test('jamais déclenchée : peut toujours déclencher', () {
      const alert = PriceAlert(
        id: '1',
        cryptoId: 'bitcoin',
        cryptoSymbol: 'btc',
        threshold: 50000,
        condition: AlertCondition.above,
      );
      expect(alert.canTriggerAgain, true);
    });

    test('déclenchée il y a moins de 20 min : ne peut pas redéclencher', () {
      final alert = PriceAlert(
        id: '1',
        cryptoId: 'bitcoin',
        cryptoSymbol: 'btc',
        threshold: 50000,
        condition: AlertCondition.above,
        lastTriggeredAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      expect(alert.canTriggerAgain, false);
    });

    test('déclenchée il y a exactement 20 min : peut redéclencher', () {
      final alert = PriceAlert(
        id: '1',
        cryptoId: 'bitcoin',
        cryptoSymbol: 'btc',
        threshold: 50000,
        condition: AlertCondition.above,
        lastTriggeredAt: DateTime.now().subtract(const Duration(minutes: 20)),
      );
      expect(alert.canTriggerAgain, true);
    });

    test('déclenchée il y a plus de 20 min : peut redéclencher', () {
      final alert = PriceAlert(
        id: '1',
        cryptoId: 'bitcoin',
        cryptoSymbol: 'btc',
        threshold: 50000,
        condition: AlertCondition.above,
        lastTriggeredAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(alert.canTriggerAgain, true);
    });
  });

  group('PriceAlert.copyWith', () {
    test('ne modifie que les champs fournis', () {
      const original = PriceAlert(
        id: '1',
        cryptoId: 'bitcoin',
        cryptoSymbol: 'btc',
        threshold: 50000,
        condition: AlertCondition.above,
        active: true,
      );

      final updated = original.copyWith(active: false);

      expect(updated.active, false);
      expect(updated.id, original.id);
      expect(updated.threshold, original.threshold);
      expect(updated.condition, original.condition);
    });

    test('met à jour lastTriggeredAt sans toucher aux autres champs', () {
      const original = PriceAlert(
        id: '1',
        cryptoId: 'bitcoin',
        cryptoSymbol: 'btc',
        threshold: 50000,
        condition: AlertCondition.above,
      );
      final now = DateTime.now();

      final updated = original.copyWith(lastTriggeredAt: now);

      expect(updated.lastTriggeredAt, now);
      expect(updated.threshold, original.threshold);
      expect(updated.active, original.active);
    });
  });

  group('PriceAlert JSON (round-trip)', () {
    test('toJson puis fromJson redonne un objet équivalent', () {
      final original = PriceAlert(
        id: 'abc-123',
        cryptoId: 'ethereum',
        cryptoSymbol: 'eth',
        threshold: 3000.5,
        condition: AlertCondition.below,
        active: false,
        lastTriggeredAt: DateTime(2026, 1, 1, 12, 30),
      );

      final json = original.toJson();
      final restored = PriceAlert.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.cryptoId, original.cryptoId);
      expect(restored.cryptoSymbol, original.cryptoSymbol);
      expect(restored.threshold, original.threshold);
      expect(restored.condition, original.condition);
      expect(restored.active, original.active);
      expect(restored.lastTriggeredAt, original.lastTriggeredAt);
    });

    test('fromJson avec lastTriggeredAt absent donne null', () {
      final json = {
        'id': '1',
        'cryptoId': 'bitcoin',
        'cryptoSymbol': 'btc',
        'threshold': 50000.0,
        'condition': 'above',
        'active': true,
        'lastTriggeredAt': null,
      };

      final alert = PriceAlert.fromJson(json);
      expect(alert.lastTriggeredAt, isNull);
    });

    test('fromJson sans champ active défaut à true', () {
      final json = {
        'id': '1',
        'cryptoId': 'bitcoin',
        'cryptoSymbol': 'btc',
        'threshold': 50000.0,
        'condition': 'above',
      };

      final alert = PriceAlert.fromJson(json);
      expect(alert.active, true);
    });
  });
}