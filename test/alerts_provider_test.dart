import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cryptowatch/features/alerts/domain/price_alert.dart';
import 'package:cryptowatch/features/alerts/presentation/providers/alerts_provider.dart';
import 'package:cryptowatch/features/market/data/repositories/market_repository.dart';
import 'package:cryptowatch/features/market/domain/binance_ticker.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';
import 'package:cryptowatch/features/market/presentation/providers/realtime_provider.dart';

class MockMarketRepository extends Mock implements MarketRepository {}

void main() {
  late MockMarketRepository mockRepository;

  final btc = Crypto(
    id: 'bitcoin',
    name: 'Bitcoin',
    symbol: 'btc',
    currentPrice: 45000.0,
    lastUpdated: DateTime(2026, 1, 1),
  );

  PriceAlert alertAbove(double threshold, {bool active = true}) => PriceAlert(
    id: 'a-$threshold',
    cryptoId: 'bitcoin',
    cryptoSymbol: 'btc',
    cryptoName: 'Bitcoin',
    threshold: threshold,
    condition: AlertCondition.above,
    active: active,
  );

  ({ProviderContainer container, StreamController<BinanceTicker> tickers})
  makeContainer({DateTime Function()? now}) {
    final tickerController = StreamController<BinanceTicker>.broadcast();
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        marketRepositoryProvider.overrideWithValue(mockRepository),
        tickerStreamProvider.overrideWith((ref) => tickerController.stream),
        if (now != null) nowProvider.overrideWithValue(now),
      ],
    );
    // Simule le keep-alive d'AppShell.
    container.listen(alertsProvider, (_, _) {});
    return (container: container, tickers: tickerController);
  }

  Future<void> settleMarket(ProviderContainer container) async {
    var attempts = 0;
    while (container.read(marketProvider).isLoading && attempts < 50) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      attempts++;
    }
  }

  setUp(() {
    mockRepository = MockMarketRepository();
    when(() => mockRepository.fetchTopCryptos()).thenAnswer((_) async => [btc]);
  });

  test(
    'un tick qui franchit le seuil émet un événement et arme le cooldown',
    () async {
      final setup = makeContainer();
      addTearDown(() {
        setup.container.dispose();
        setup.tickers.close();
      });
      await settleMarket(setup.container);

      setup.container.read(alertsProvider.notifier).addAlert(alertAbove(44000));

      setup.tickers.add(
        const BinanceTicker(symbol: 'btc', raw: {'c': '45100.00'}),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final event = setup.container.read(alertEventProvider);
      expect(event, isNotNull);
      expect(event!.cryptoName, 'Bitcoin');
      expect(
        setup.container.read(alertsProvider).first.lastTriggeredAt,
        isNotNull,
      );
    },
  );

  test('seuil non franchi : aucun événement', () async {
    final setup = makeContainer();
    addTearDown(() {
      setup.container.dispose();
      setup.tickers.close();
    });
    await settleMarket(setup.container);

    setup.container.read(alertsProvider.notifier).addAlert(alertAbove(99999));

    setup.tickers.add(
      const BinanceTicker(symbol: 'btc', raw: {'c': '45100.00'}),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(setup.container.read(alertEventProvider), isNull);
  });

  test('alerte désactivée : aucun événement même seuil franchi', () async {
    final setup = makeContainer();
    addTearDown(() {
      setup.container.dispose();
      setup.tickers.close();
    });
    await settleMarket(setup.container);

    setup.container
        .read(alertsProvider.notifier)
        .addAlert(alertAbove(44000, active: false));

    setup.tickers.add(
      const BinanceTicker(symbol: 'btc', raw: {'c': '45100.00'}),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(setup.container.read(alertEventProvider), isNull);
  });

  test('le cooldown bloque un second déclenchement immédiat', () async {
    var fakeNow = DateTime(2026, 9, 15, 12, 0);
    final setup = makeContainer(now: () => fakeNow);
    addTearDown(() {
      setup.container.dispose();
      setup.tickers.close();
    });
    await settleMarket(setup.container);

    setup.container.read(alertsProvider.notifier).addAlert(alertAbove(44000));

    setup.tickers.add(
      const BinanceTicker(symbol: 'btc', raw: {'c': '45100.00'}),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(setup.container.read(alertEventProvider), isNotNull);

    // On efface l'événement, un 2e tick arrive DANS la fenêtre de cooldown.
    setup.container.read(alertEventProvider.notifier).state = null;
    setup.tickers.add(
      const BinanceTicker(symbol: 'btc', raw: {'c': '45200.00'}),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(
      setup.container.read(alertEventProvider),
      isNull,
      reason: 'le cooldown doit bloquer',
    );

    // Le temps passe au-delà du cooldown : ça redéclenche.
    fakeNow = fakeNow.add(PriceAlert.cooldown);
    setup.tickers.add(
      const BinanceTicker(symbol: 'btc', raw: {'c': '45300.00'}),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(setup.container.read(alertEventProvider), isNotNull);
  });

  test('symbole absent du marché : ignoré sans erreur', () async {
    final setup = makeContainer();
    addTearDown(() {
      setup.container.dispose();
      setup.tickers.close();
    });
    await settleMarket(setup.container);

    setup.container
        .read(alertsProvider.notifier)
        .addAlert(
          const PriceAlert(
            id: 'sol-1',
            cryptoId: 'solana',
            cryptoSymbol: 'sol',
            cryptoName: 'Solana',
            threshold: 100,
            condition: AlertCondition.above,
          ),
        );

    setup.tickers.add(
      const BinanceTicker(symbol: 'btc', raw: {'c': '45100.00'}),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(setup.container.read(alertEventProvider), isNull);
    expect(setup.container.read(alertsProvider), hasLength(1));
  });

  test('add / remove / toggle', () {
    final setup = makeContainer();
    addTearDown(() {
      setup.container.dispose();
      setup.tickers.close();
    });

    final notifier = setup.container.read(alertsProvider.notifier);
    final alert = alertAbove(50000);
    notifier.addAlert(alert);
    expect(setup.container.read(alertsProvider), hasLength(1));

    notifier.toggleActive(alert.id);
    expect(setup.container.read(alertsProvider).first.active, isFalse);

    notifier.removeAlert(alert.id);
    expect(setup.container.read(alertsProvider), isEmpty);
  });
}
