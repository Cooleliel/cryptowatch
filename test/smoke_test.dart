import 'package:cryptowatch/app/app.dart';
import 'package:cryptowatch/features/market/data/repositories/market_repository.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/fake_realtime_overrides.dart';

class MockMarketRepository extends Mock implements MarketRepository {}

void main() {
  late MockMarketRepository mockRepository;

  Widget app() {
    return ProviderScope(
      overrides: [
        marketRepositoryProvider.overrideWithValue(mockRepository),
        ...fakeRealtimeOverrides(),
      ],
      child: const CryptoWatchApp(),
    );
  }

  setUp(() {
    mockRepository = MockMarketRepository();
    when(() => mockRepository.fetchTopCryptos()).thenAnswer(
      (_) async => [
        Crypto(
          id: 'bitcoin',
          name: 'Bitcoin',
          symbol: 'btc',
          currentPrice: 45000.0,
          lastUpdated: DateTime(2026, 1, 1),
        ),
      ],
    );
  });

  testWidgets("L'application démarre sur l'écran de marché", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app());
    expect(find.text('CryptoWatch'), findsOneWidget);
  });

  testWidgets("Les onglets naviguent entre Marché et Watchlist", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Watchlist'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ma watchlist'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Marché'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('CryptoWatch'), findsOneWidget);
  });
}