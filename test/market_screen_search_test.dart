import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cryptowatch/features/market/data/repositories/market_repository.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';
import 'package:cryptowatch/features/market/presentation/screens/market_screen.dart';

import 'helpers/fake_realtime_overrides.dart';

class MockMarketRepository extends Mock implements MarketRepository {}

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

  Future<void> pumpMarket(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketRepositoryProvider.overrideWithValue(mockRepository),
          ...fakeRealtimeOverrides(),
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

  testWidgets('affiche le champ de recherche une fois le marché chargé', (
    tester,
  ) async {
    await pumpMarket(tester);

    expect(find.byKey(const Key('market-search-field')), findsOneWidget);
    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.text('Ethereum'), findsOneWidget);
  });

  testWidgets('filtre la liste par nom', (tester) async {
    await pumpMarket(tester);

    await tester.enterText(
      find.byKey(const Key('market-search-field')),
      'bit',
    );
    await tester.pump();

    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.text('Ethereum'), findsNothing);
  });

  testWidgets('filtre la liste par symbole', (tester) async {
    await pumpMarket(tester);

    await tester.enterText(
      find.byKey(const Key('market-search-field')),
      'ETH',
    );
    await tester.pump();

    expect(find.text('Ethereum'), findsOneWidget);
    expect(find.text('Bitcoin'), findsNothing);
  });

  testWidgets('affiche un état vide si aucune crypto ne correspond', (
    tester,
  ) async {
    await pumpMarket(tester);

    await tester.enterText(
      find.byKey(const Key('market-search-field')),
      'solana',
    );
    await tester.pump();

    expect(find.text('Aucune crypto trouvée'), findsOneWidget);
    expect(find.byKey(const Key('market-search-field')), findsOneWidget);
  });
}