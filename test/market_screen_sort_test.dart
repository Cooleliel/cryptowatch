import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cryptowatch/features/market/data/repositories/market_repository.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';
import 'package:cryptowatch/features/market/presentation/screens/market_screen.dart';

class MockMarketRepository extends Mock implements MarketRepository {}

void main() {
  late MockMarketRepository mockRepository;

  final sampleCryptos = [
    Crypto(
      id: 'ethereum',
      name: 'Ethereum',
      symbol: 'eth',
      currentPrice: 3000.0,
      lastUpdated: DateTime(2026, 1, 1),
    ),
    Crypto(
      id: 'bitcoin',
      name: 'Bitcoin',
      symbol: 'btc',
      currentPrice: 45000.0,
      lastUpdated: DateTime(2026, 1, 1),
    ),
  ];

  Future<void> pumpMarket(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: const MaterialApp(home: MarketScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  setUp(() {
    mockRepository = MockMarketRepository();
    when(
      () => mockRepository.fetchTopCryptos(),
    ).thenAnswer((_) async => sampleCryptos);
  });

  testWidgets('affiche les critères de tri une fois le marché chargé', (
    tester,
  ) async {
    await pumpMarket(tester);

    expect(find.byKey(const Key('market-sort-price')), findsOneWidget);
    expect(find.byKey(const Key('market-sort-variation')), findsOneWidget);
    expect(find.byKey(const Key('market-sort-market-cap')), findsOneWidget);
  });

  testWidgets('trie par prix du plus élevé au plus bas', (tester) async {
    await pumpMarket(tester);

    await tester.tap(find.byKey(const Key('market-sort-price')));
    await tester.pump();

    final bitcoin = tester.getTopLeft(find.text('Bitcoin'));
    final ethereum = tester.getTopLeft(find.text('Ethereum'));
    expect(bitcoin.dy, lessThan(ethereum.dy));
  });

  testWidgets('un second tap inverse le tri par prix', (tester) async {
    await pumpMarket(tester);

    await tester.tap(find.byKey(const Key('market-sort-price')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('market-sort-price')));
    await tester.pump();

    final bitcoin = tester.getTopLeft(find.text('Bitcoin'));
    final ethereum = tester.getTopLeft(find.text('Ethereum'));
    expect(ethereum.dy, lessThan(bitcoin.dy));
  });
}
