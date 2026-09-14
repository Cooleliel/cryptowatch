import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cryptowatch/features/market/data/repositories/market_repository.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_filter_provider.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_filter_state.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';
import 'package:cryptowatch/features/market/presentation/providers/realtime_provider.dart';
import 'package:cryptowatch/features/market/presentation/providers/visible_cryptos_provider.dart';

class MockMarketRepository extends Mock implements MarketRepository {}

void main() {
  late MockMarketRepository mockRepository;
  late ProviderContainer container;

  // 'solana' ne contient aucune sous-chaîne commune avec 'ethereum'/'eth' —
  // évite la collision qu'on avait avec 'tether' (contient "eth" : t-ETH-er).
  final cryptos = [
    Crypto(
      id: 'bitcoin',
      name: 'Bitcoin',
      symbol: 'btc',
      currentPrice: 45000.0,
      priceChangePercentage24h: 2.0,
      marketCap: 900000000000,
      lastUpdated: DateTime(2026, 1, 1),
    ),
    Crypto(
      id: 'ethereum',
      name: 'Ethereum',
      symbol: 'eth',
      currentPrice: 3000.0,
      priceChangePercentage24h: -1.0,
      marketCap: 400000000000,
      lastUpdated: DateTime(2026, 1, 1),
    ),
    Crypto(
      id: 'solana',
      name: 'Solana',
      symbol: 'sol',
      currentPrice: 150.0, // pas de variation ni de market cap
      lastUpdated: DateTime(2026, 1, 1),
    ),
  ];

  setUp(() async {
    mockRepository = MockMarketRepository();
    when(
      () => mockRepository.fetchTopCryptos(),
    ).thenAnswer((_) async => cryptos);

    container = ProviderContainer(
      overrides: [
        marketRepositoryProvider.overrideWithValue(mockRepository),
        tickerStreamProvider.overrideWith((ref) => const Stream.empty()),
      ],
    );
    await container.read(marketProvider.future);
  });

  tearDown(() => container.dispose());

  test('sans filtre ni tri, renvoie la liste brute', () {
    final result = container.read(visibleCryptosProvider).value;
    expect(result, cryptos);
  });

  test('filtre par nom, insensible à la casse', () {
    container.read(marketFilterProvider.notifier).setQuery('BITCOIN');
    final result = container.read(visibleCryptosProvider).value!;
    expect(result, [cryptos[0]]);
  });

  test('filtre par symbole', () {
    container.read(marketFilterProvider.notifier).setQuery('eth');
    final result = container.read(visibleCryptosProvider).value!;
    expect(result, [cryptos[1]]); // uniquement Ethereum, plus de collision
  });

  test('tri par prix descendant', () {
    container
        .read(marketFilterProvider.notifier)
        .setSortField(MarketSortField.price);
    final result = container.read(visibleCryptosProvider).value!;
    expect(result.map((c) => c.symbol), ['btc', 'eth', 'sol']);
  });

  test('tri par prix ascendant (second tap)', () {
    final notifier = container.read(marketFilterProvider.notifier);
    notifier.setSortField(MarketSortField.price);
    notifier.setSortField(MarketSortField.price);
    final result = container.read(visibleCryptosProvider).value!;
    expect(result.map((c) => c.symbol), ['sol', 'eth', 'btc']);
  });

  test('tri par variation : les valeurs null finissent en dernier', () {
    container
        .read(marketFilterProvider.notifier)
        .setSortField(MarketSortField.variation);
    final result = container.read(visibleCryptosProvider).value!;
    // btc (2.0) puis eth (-1.0) puis sol (null, toujours en dernier)
    expect(result.map((c) => c.symbol), ['btc', 'eth', 'sol']);
  });

  test('recherche et tri combinés', () {
    final notifier = container.read(marketFilterProvider.notifier);
    notifier.setQuery('ethereum'); // ne matche que le nom "Ethereum"
    notifier.setSortField(MarketSortField.price);

    final result = container.read(visibleCryptosProvider).value!;
    expect(result.map((c) => c.symbol), ['eth']);
  });

  test('recherche sans résultat renvoie une liste vide', () {
    container.read(marketFilterProvider.notifier).setQuery('doge');
    final result = container.read(visibleCryptosProvider).value;
    expect(result, isEmpty);
  });
}