import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cryptowatch/app/app.dart';
import 'package:cryptowatch/features/market/data/repositories/market_repository.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';

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

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketRepositoryProvider.overrideWithValue(mockRepository),
          ...fakeRealtimeOverrides(),
        ],
        child: const CryptoWatchApp(),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> goToWatchlistTab(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Watchlist'),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    mockRepository = MockMarketRepository();
    when(
      () => mockRepository.fetchTopCryptos(),
    ).thenAnswer((_) async => sampleCryptos);
  });

  testWidgets('une crypto étoilée apparaît dans la watchlist', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('favorite-toggle-bitcoin')));
    await tester.pump();

    await goToWatchlistTab(tester);

    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.text('Ethereum'), findsNothing);
  });

  testWidgets('retirer le favori vide la watchlist', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('favorite-toggle-bitcoin')));
    await tester.pump();
    await goToWatchlistTab(tester);
    expect(find.text('Bitcoin'), findsOneWidget);

    // On retire le favori depuis la watchlist elle-même
    await tester.tap(find.byKey(const Key('favorite-toggle-bitcoin')));
    await tester.pump();

    expect(find.textContaining("Touche l'étoile"), findsOneWidget);
  });
}
