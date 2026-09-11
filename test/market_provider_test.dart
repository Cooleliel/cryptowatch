import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cryptowatch/features/market/data/repositories/market_repository.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_state.dart';

class MockMarketRepository extends Mock implements MarketRepository {}

void main() {
  late MockMarketRepository mockRepository;
  late ProviderContainer container;

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

  setUp(() {
    mockRepository = MockMarketRepository();
    container = ProviderContainer(
      overrides: [
        marketRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('état initial est MarketLoading avant résolution du fetch', () {
    when(() => mockRepository.fetchTopCryptos())
        .thenAnswer((_) async => sampleCryptos);

    container.read(marketProvider.notifier); // déclenche le build/constructeur
    expect(container.read(marketProvider), isA<MarketLoading>());
  });

  test('passe à MarketLoaded avec les cryptos en cas de succès', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenAnswer((_) async => sampleCryptos);

    // Attend la résolution du Future lancé dans le constructeur du Notifier
    await container.read(marketProvider.notifier).retry();

    final state = container.read(marketProvider);
    expect(state, isA<MarketLoaded>());
    expect((state as MarketLoaded).cryptos, sampleCryptos);
  });

  test('passe à MarketError en cas d\'exception du repository', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenThrow(Exception('Network error'));

    await container.read(marketProvider.notifier).retry();

    final state = container.read(marketProvider);
    expect(state, isA<MarketError>());
  });

  test('retry() relance le chargement et repasse par MarketLoading', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenAnswer((_) async => sampleCryptos);

    final notifier = container.read(marketProvider.notifier);
    final future = notifier.retry();

    expect(container.read(marketProvider), isA<MarketLoading>());
    await future;
    expect(container.read(marketProvider), isA<MarketLoaded>());
  });

  test('MarketLoaded contient une liste vide si le repository renvoie []', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenAnswer((_) async => []);

    await container.read(marketProvider.notifier).retry();

    final state = container.read(marketProvider) as MarketLoaded;
    expect(state.cryptos, isEmpty);
  });

  test('setQuery filtre par nom sans modifier la liste brute', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenAnswer((_) async => sampleCryptos);

    await container.read(marketProvider.notifier).retry();
    container.read(marketProvider.notifier).setQuery('bit');

    final state = container.read(marketProvider) as MarketLoaded;
    expect(state.cryptos, sampleCryptos);
    expect(state.visibleCryptos, [sampleCryptos.first]);
  });

  test('setQuery filtre par symbole sans tenir compte de la casse', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenAnswer((_) async => sampleCryptos);

    await container.read(marketProvider.notifier).retry();
    container.read(marketProvider.notifier).setQuery('ETH');

    final state = container.read(marketProvider) as MarketLoaded;
    expect(state.visibleCryptos.single.symbol, 'eth');
  });

  test('setQuery sans correspondance laisse visibleCryptos vide', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenAnswer((_) async => sampleCryptos);

    await container.read(marketProvider.notifier).retry();
    container.read(marketProvider.notifier).setQuery('solana');

    final state = container.read(marketProvider) as MarketLoaded;
    expect(state.visibleCryptos, isEmpty);
    expect(state.cryptos, hasLength(2));
  });

  test('query vide réaffiche toute la liste', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenAnswer((_) async => sampleCryptos);

    await container.read(marketProvider.notifier).retry();
    container.read(marketProvider.notifier).setQuery('eth');
    container.read(marketProvider.notifier).setQuery('');

    final state = container.read(marketProvider) as MarketLoaded;
    expect(state.visibleCryptos, sampleCryptos);
  });

  test('retry réinitialise la recherche', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenAnswer((_) async => sampleCryptos);

    await container.read(marketProvider.notifier).retry();
    container.read(marketProvider.notifier).setQuery('eth');
    await container.read(marketProvider.notifier).retry();

    final state = container.read(marketProvider) as MarketLoaded;
    expect(state.query, isEmpty);
    expect(state.visibleCryptos, sampleCryptos);
  });

  test('setQuery est ignoré en MarketError', () async {
    when(() => mockRepository.fetchTopCryptos())
        .thenThrow(Exception('Network error'));

    await container.read(marketProvider.notifier).retry();
    container.read(marketProvider.notifier).setQuery('btc');
    expect(container.read(marketProvider), isA<MarketError>());
  });

  test('visibleCryptos ignore les espaces autour de la query', () {
    final loaded = MarketLoaded(sampleCryptos, query: '  ETH  ');
    expect(loaded.visibleCryptos.single.name, 'Ethereum');
  });
}