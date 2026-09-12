import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cryptowatch/app/app.dart';
import 'package:cryptowatch/features/crypto_detail/data/repositories/price_history_repository.dart';
import 'package:cryptowatch/features/crypto_detail/domain/price_point.dart';
import 'package:cryptowatch/features/crypto_detail/presentation/providers/price_history_provider.dart';
import 'package:cryptowatch/features/crypto_detail/presentation/screens/crypto_detail_screen.dart';
import 'package:cryptowatch/features/market/data/repositories/market_repository.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';

import 'helpers/fake_realtime_overrides.dart';

class MockMarketRepository extends Mock implements MarketRepository {}

class MockPriceHistoryRepository extends Mock
    implements PriceHistoryRepository {}

void main() {
  late MockMarketRepository mockMarket;
  late MockPriceHistoryRepository mockHistory;

  final samplePoints = [
    PricePoint(time: DateTime(2026, 9, 4), price: 2800),
    PricePoint(time: DateTime(2026, 9, 10), price: 3000),
  ];

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
      priceChangePercentage24h: 1.2,
      marketCapRank: 2,
      lastUpdated: DateTime(2026, 1, 1),
    ),
  ];

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketRepositoryProvider.overrideWithValue(mockMarket),
          priceHistoryRepositoryProvider.overrideWithValue(mockHistory),
          ...fakeRealtimeOverrides(),
        ],
        child: const CryptoWatchApp(),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  setUp(() {
    mockMarket = MockMarketRepository();
    mockHistory = MockPriceHistoryRepository();
    when(() => mockMarket.fetchTopCryptos())
        .thenAnswer((_) async => sampleCryptos);
    when(() => mockHistory.fetchLast7Days(any()))
        .thenAnswer((_) async => samplePoints);
  });

  testWidgets('un tap sur une carte ouvre la fiche de cette crypto',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('crypto-card-ethereum')));
    await tester.pumpAndSettle();

    expect(find.byType(CryptoDetailScreen), findsOneWidget);
    expect(find.text('Ethereum'), findsOneWidget);
    expect(find.text('Rang 2'), findsOneWidget);
    expect(find.text(r'$3 000,00'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Bitcoin'), findsNothing);
  });

  testWidgets('le retour ramène à la liste du marché', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('crypto-card-ethereum')));
    await tester.pumpAndSettle();
    expect(find.byType(CryptoDetailScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.byType(CryptoDetailScreen), findsNothing);
    expect(find.text('CryptoWatch'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Ethereum'), findsOneWidget);
  });
}
