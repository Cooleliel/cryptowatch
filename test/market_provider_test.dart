import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cryptowatch/features/market/data/repositories/market_repository.dart';
import 'package:cryptowatch/features/market/domain/binance_ticker.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';
import 'package:cryptowatch/features/market/presentation/providers/realtime_provider.dart';
import 'package:cryptowatch/shared/errors/app_exception.dart';

class MockMarketRepository extends Mock implements MarketRepository {}

/// Attend que [marketProvider] sorte de l'état de chargement.
///
/// `retry: null` sur le container désactive le retry automatique de
/// Riverpod pour les providers en échec, donc `isLoading` devient `false`
/// dès le premier essai (succès ou échec) — pas besoin d'attendre au-delà
/// d'un très court délai.
Future<AsyncValue<List<Crypto>>> _settle(ProviderContainer container) async {
  var state = container.read(marketProvider);
  var attempts = 0;
  while (state.isLoading && attempts < 50) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    state = container.read(marketProvider);
    attempts++;
  }
  return state;
}

/// Attend qu'une crypto donnée atteigne un prix précis, pour éviter les
/// délais fixes fragiles après l'envoi d'un tick sur le flux temps réel.
// ignore: unused_element
Future<List<Crypto>> _waitForPrice(
  ProviderContainer container,
  String symbol,
  double expectedPrice,
) async {
  var attempts = 0;
  while (attempts < 50) {
    final cryptos = container.read(marketProvider).value;
    if (cryptos != null) {
      final match = cryptos.where((c) => c.symbol == symbol);
      if (match.isNotEmpty && match.first.currentPrice == expectedPrice) {
        return cryptos;
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
    attempts++;
  }
  return container.read(marketProvider).value ?? [];
}

void main() {
  late MockMarketRepository mockRepository;

  final sampleCryptos = [
    Crypto(
      id: 'bitcoin',
      name: 'Bitcoin',
      symbol: 'btc',
      currentPrice: 45000.0,
      lastUpdated: DateTime(2026, 1, 1),
    ),
    Crypto(
      id: 'ethereum',
      name: 'Ethereum',
      symbol: 'eth',
      currentPrice: 3000.0,
      lastUpdated: DateTime(2026, 1, 1),
    ),
  ];

  ({ProviderContainer container, StreamController<BinanceTicker> tickers})
  makeContainer() {
    final tickerController = StreamController<BinanceTicker>.broadcast();
    final container = ProviderContainer(
      // Désactive le retry automatique : une erreur devient AsyncError
      // immédiatement, au lieu de rester en AsyncLoading(retrying: true).
      retry: (retryCount, error) => null,
      overrides: [
        marketRepositoryProvider.overrideWithValue(mockRepository),
        tickerStreamProvider.overrideWith((ref) => tickerController.stream),
      ],
    );
    return (container: container, tickers: tickerController);
  }

  setUp(() {
    mockRepository = MockMarketRepository();
  });

  group('chargement initial (T-04b)', () {
    test('renvoie la liste des cryptos en cas de succès', () async {
      when(
        () => mockRepository.fetchTopCryptos(),
      ).thenAnswer((_) async => sampleCryptos);

      final setup = makeContainer();
      addTearDown(() {
        setup.container.dispose();
        setup.tickers.close();
      });

      final state = await _settle(setup.container);
      expect(state, isA<AsyncData<List<Crypto>>>());
      expect(state.value, sampleCryptos);
    });

    test('propage une NetworkException telle quelle', () async {
      when(
        () => mockRepository.fetchTopCryptos(),
      ).thenThrow(const NetworkException('connexion perdue'));

      final setup = makeContainer();
      addTearDown(() {
        setup.container.dispose();
        setup.tickers.close();
      });

      final state = await _settle(setup.container);
      expect(state, isA<AsyncError>());
      expect(state.error, isA<NetworkException>());
    });

    test('propage une RateLimitException telle quelle', () async {
      when(
        () => mockRepository.fetchTopCryptos(),
      ).thenThrow(const RateLimitException());

      final setup = makeContainer();
      addTearDown(() {
        setup.container.dispose();
        setup.tickers.close();
      });

      final state = await _settle(setup.container);
      expect(state, isA<AsyncError>());
      expect(state.error, isA<RateLimitException>());
    });

    test('propage une InvalidDataException telle quelle', () async {
      when(
        () => mockRepository.fetchTopCryptos(),
      ).thenThrow(const InvalidDataException('format inattendu'));

      final setup = makeContainer();
      addTearDown(() {
        setup.container.dispose();
        setup.tickers.close();
      });

      final state = await _settle(setup.container);
      expect(state, isA<AsyncError>());
      expect(state.error, isA<InvalidDataException>());
    });

    test('retry (ref.invalidate) relance un chargement propre', () async {
      when(
        () => mockRepository.fetchTopCryptos(),
      ).thenThrow(const NetworkException('timeout'));

      final setup = makeContainer();
      addTearDown(() {
        setup.container.dispose();
        setup.tickers.close();
      });

      final errorState = await _settle(setup.container);
      expect(errorState, isA<AsyncError>());
      expect(errorState.error, isA<NetworkException>());

      when(
        () => mockRepository.fetchTopCryptos(),
      ).thenAnswer((_) async => sampleCryptos);

      setup.container.invalidate(marketProvider);

      final loadedState = await _settle(setup.container);
      expect(loadedState, isA<AsyncData<List<Crypto>>>());
      expect(loadedState.value, sampleCryptos);
    });
  });

  group('mise à jour temps réel (T-08a)', () {
    test('met à jour uniquement la crypto correspondant au symbole (diagnostic)', () async {
    when(
      () => mockRepository.fetchTopCryptos(),
    ).thenAnswer((_) async => sampleCryptos);

    final setup = makeContainer();
    addTearDown(() {
      setup.container.dispose();
      setup.tickers.close();
    });

    await _settle(setup.container);

    final completer = Completer<void>();
    final sub = setup.container.listen<AsyncValue<List<Crypto>>>(
      marketProvider,
      (previous, next) {
        final btc = next.value?.firstWhere(
          (c) => c.symbol == 'btc',
          orElse: () => sampleCryptos[0],
        );
        if (btc != null && btc.currentPrice == 46000.00 && !completer.isCompleted) {
          completer.complete();
        }
      },
    );
  addTearDown(sub.close);

  setup.tickers.add(
    const BinanceTicker(
      symbol: 'btc',
      raw: {'c': '46000.00', 'P': '2.2', 'E': 1735689600000},
    ),
  );

  await completer.future.timeout(
    const Duration(seconds: 2),
    onTimeout: () => fail('La mise à jour du prix n\'a jamais été notifiée'),
  );
});

    test('ignore un tick pour un symbole inconnu', () async {
      when(
        () => mockRepository.fetchTopCryptos(),
      ).thenAnswer((_) async => sampleCryptos);

      final setup = makeContainer();
      addTearDown(() {
        setup.container.dispose();
        setup.tickers.close();
      });

      await _settle(setup.container);

      setup.tickers.add(
        const BinanceTicker(symbol: 'sol', raw: {'c': '200.00'}),
      );
      // Pas de valeur à attendre ici (rien ne doit changer) : un court
      // délai fixe suffit puisqu'on vérifie une absence d'effet.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final updated = setup.container.read(marketProvider).value!;
      expect(updated, sampleCryptos);
    });

    test(
      'un tick reçu avant la fin du chargement initial est sans effet',
      () async {
        when(() => mockRepository.fetchTopCryptos()).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 80));
          return sampleCryptos;
        });

        final setup = makeContainer();
        addTearDown(() {
          setup.container.dispose();
          setup.tickers.close();
        });

        setup.container.read(marketProvider); // déclenche build()

        setup.tickers.add(
          const BinanceTicker(symbol: 'btc', raw: {'c': '99999.00'}),
        );

        final state = await _settle(setup.container);
        expect(
          state.value!.firstWhere((c) => c.symbol == 'btc').currentPrice,
          45000.0,
        );
      },
    );
  });
}