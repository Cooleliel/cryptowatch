import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cryptowatch/features/alerts/data/alerts_repository.dart';
import 'package:cryptowatch/features/alerts/domain/price_alert.dart';
import 'package:cryptowatch/features/alerts/presentation/providers/alerts_provider.dart';
import 'package:cryptowatch/features/market/data/repositories/market_repository.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';
import 'package:cryptowatch/features/market/presentation/providers/realtime_provider.dart';
import 'package:cryptowatch/shared/notifications/notification_service.dart';

class MockAlertsRepository extends Mock implements AlertsRepository {}

class MockNotificationService extends Mock implements NotificationService {}

class MockMarketRepository extends Mock implements MarketRepository {}

void main() {
  late MockAlertsRepository mockAlertsRepo;
  late MockNotificationService mockNotifService;
  late MockMarketRepository mockMarketRepo;

  setUpAll(() {
    registerFallbackValue(AlertCondition.above);
  });

  final btc = Crypto(
    id: 'bitcoin',
    name: 'Bitcoin',
    symbol: 'btc',
    currentPrice: 45000.0,
    lastUpdated: DateTime(2026, 1, 1),
  );

  ProviderContainer makeContainer() {
    return ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        alertsRepositoryProvider.overrideWithValue(mockAlertsRepo),
        notificationServiceProvider.overrideWithValue(mockNotifService),
        marketRepositoryProvider.overrideWithValue(mockMarketRepo),
        tickerStreamProvider.overrideWith((ref) => const Stream.empty()),
      ],
    );
  }

  Future<AsyncValue<List<PriceAlert>>> settleAlerts(
    ProviderContainer container,
  ) async {
    var state = container.read(alertsProvider);
    var attempts = 0;
    while (state.isLoading && attempts < 50) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      state = container.read(alertsProvider);
      attempts++;
    }
    return state;
  }

  setUp(() {
    mockAlertsRepo = MockAlertsRepository();
    mockNotifService = MockNotificationService();
    mockMarketRepo = MockMarketRepository();

    when(() => mockMarketRepo.fetchTopCryptos()).thenAnswer((_) async => [btc]);
    when(
      () => mockNotifService.showPriceAlert(
        cryptoName: any(named: 'cryptoName'),
        price: any(named: 'price'),
        condition: any(named: 'condition'),
        threshold: any(named: 'threshold'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockAlertsRepo.saveAlerts(any())).thenAnswer((_) async {});
  });

  test('charge les alertes existantes au démarrage', () async {
    when(() => mockAlertsRepo.loadAlerts()).thenAnswer(
      (_) async => [
        const PriceAlert(
          id: '1',
          cryptoId: 'bitcoin',
          cryptoSymbol: 'btc',
          threshold: 50000,
          condition: AlertCondition.above,
        ),
      ],
    );

    final container = makeContainer();
    addTearDown(container.dispose);

    final state = await settleAlerts(container);
    expect(state.value, hasLength(1));
  });

  test('déclenche la notification quand le seuil est franchi', () async {
    when(() => mockAlertsRepo.loadAlerts()).thenAnswer(
      (_) async => [
        const PriceAlert(
          id: '1',
          cryptoId: 'bitcoin',
          cryptoSymbol: 'btc',
          threshold: 44000, // déjà franchi par btc.currentPrice = 45000
          condition: AlertCondition.above,
        ),
      ],
    );

    final container = makeContainer();
    addTearDown(container.dispose);

    await settleAlerts(container);
    // Laisse le ref.listen(marketProvider) déclencher _checkThresholds.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    verify(
      () => mockNotifService.showPriceAlert(
        cryptoName: 'Bitcoin',
        price: 45000.0,
        condition: AlertCondition.above,
        threshold: 44000,
      ),
    ).called(1);
  });

  test('ne déclenche pas si le seuil n\'est pas franchi', () async {
    when(() => mockAlertsRepo.loadAlerts()).thenAnswer(
      (_) async => [
        const PriceAlert(
          id: '1',
          cryptoId: 'bitcoin',
          cryptoSymbol: 'btc',
          threshold: 50000, // au-dessus du prix actuel (45000)
          condition: AlertCondition.above,
        ),
      ],
    );

    final container = makeContainer();
    addTearDown(container.dispose);

    await settleAlerts(container);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    verifyNever(
      () => mockNotifService.showPriceAlert(
        cryptoName: any(named: 'cryptoName'),
        price: any(named: 'price'),
        condition: any(named: 'condition'),
        threshold: any(named: 'threshold'),
      ),
    );
  });

  test('respecte le cooldown de 20 min : ne redéclenche pas trop tôt', () async {
    when(() => mockAlertsRepo.loadAlerts()).thenAnswer(
      (_) async => [
        PriceAlert(
          id: '1',
          cryptoId: 'bitcoin',
          cryptoSymbol: 'btc',
          threshold: 44000,
          condition: AlertCondition.above,
          lastTriggeredAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ],
    );

    final container = makeContainer();
    addTearDown(container.dispose);

    await settleAlerts(container);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    verifyNever(
      () => mockNotifService.showPriceAlert(
        cryptoName: any(named: 'cryptoName'),
        price: any(named: 'price'),
        condition: any(named: 'condition'),
        threshold: any(named: 'threshold'),
      ),
    );
  });

  test('n\'affecte pas une alerte désactivée', () async {
    when(() => mockAlertsRepo.loadAlerts()).thenAnswer(
      (_) async => [
        const PriceAlert(
          id: '1',
          cryptoId: 'bitcoin',
          cryptoSymbol: 'btc',
          threshold: 44000,
          condition: AlertCondition.above,
          active: false,
        ),
      ],
    );

    final container = makeContainer();
    addTearDown(container.dispose);

    await settleAlerts(container);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    verifyNever(
      () => mockNotifService.showPriceAlert(
        cryptoName: any(named: 'cryptoName'),
        price: any(named: 'price'),
        condition: any(named: 'condition'),
        threshold: any(named: 'threshold'),
      ),
    );
  });

  test('ignore une alerte dont la crypto n\'est pas dans le marché chargé', () async {
    when(() => mockAlertsRepo.loadAlerts()).thenAnswer(
      (_) async => [
        const PriceAlert(
          id: '1',
          cryptoId: 'solana',
          cryptoSymbol: 'sol', // absente de [btc] dans mockMarketRepo
          threshold: 100,
          condition: AlertCondition.above,
        ),
      ],
    );

    final container = makeContainer();
    addTearDown(container.dispose);

    // Ne doit pas planter, juste ignorer l'alerte sans crypto correspondante.
    final state = await settleAlerts(container);
    expect(state.value, hasLength(1)); // l'alerte reste dans la liste
  });

  group('gestion des alertes (CRUD)', () {
    test('addAlert ajoute et persiste', () async {
      when(() => mockAlertsRepo.loadAlerts()).thenAnswer((_) async => []);

      final container = makeContainer();
      addTearDown(container.dispose);
      await settleAlerts(container);

      await container.read(alertsProvider.notifier).addAlert(
            const PriceAlert(
              id: '1',
              cryptoId: 'bitcoin',
              cryptoSymbol: 'btc',
              threshold: 50000,
              condition: AlertCondition.above,
            ),
          );

      expect(container.read(alertsProvider).value, hasLength(1));
      verify(() => mockAlertsRepo.saveAlerts(any())).called(1);
    });

    test('removeAlert retire et persiste', () async {
      when(() => mockAlertsRepo.loadAlerts()).thenAnswer(
        (_) async => [
          const PriceAlert(
            id: '1',
            cryptoId: 'bitcoin',
            cryptoSymbol: 'btc',
            threshold: 50000,
            condition: AlertCondition.above,
          ),
        ],
      );

      final container = makeContainer();
      addTearDown(container.dispose);
      await settleAlerts(container);

      await container.read(alertsProvider.notifier).removeAlert('1');

      expect(container.read(alertsProvider).value, isEmpty);
    });

    test('toggleActive inverse l\'état actif', () async {
      when(() => mockAlertsRepo.loadAlerts()).thenAnswer(
        (_) async => [
          const PriceAlert(
            id: '1',
            cryptoId: 'bitcoin',
            cryptoSymbol: 'btc',
            threshold: 50000,
            condition: AlertCondition.above,
            active: true,
          ),
        ],
      );

      final container = makeContainer();
      addTearDown(container.dispose);
      await settleAlerts(container);

      await container.read(alertsProvider.notifier).toggleActive('1');

      final alerts = container.read(alertsProvider).value!;
      expect(alerts.first.active, false);
    });
  });
}