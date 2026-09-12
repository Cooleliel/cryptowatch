import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';
import 'package:cryptowatch/features/market/presentation/widgets/crypto_card.dart';
import 'helpers/fake_realtime_overrides.dart';

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

/// Notifier factice (doit étendre MarketNotifier pour la compatibilité
/// avec overrideWith).
class _FakeMarketNotifier extends MarketNotifier {
  _FakeMarketNotifier(this._cryptos);
  final List<Crypto> _cryptos;

  @override
  Future<List<Crypto>> build() async => _cryptos;
}

/// Monte une [CryptoCard] dans un [ProviderScope] avec [marketProvider]
/// surchargé sur [cryptos]. Inclut fakeRealtimeOverrides pour éviter
/// la connexion WebSocket en test.
Widget wrap(String symbol, List<Crypto> cryptos) => ProviderScope(
      overrides: [
        ...fakeRealtimeOverrides(),
        marketProvider.overrideWith(() => _FakeMarketNotifier(cryptos)),
      ],
      child: MaterialApp(
        home: Scaffold(body: CryptoCard(symbol: symbol)),
      ),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets('affiche le nom, le symbole et le prix formaté', (tester) async {
    final crypto = Crypto(
      id: 'bitcoin',
      name: 'Bitcoin',
      symbol: 'btc',
      currentPrice: 45230.5,
      lastUpdated: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(wrap('btc', [crypto]));
    await tester.pump(); // settle AsyncNotifier

    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.text('BTC'), findsOneWidget);
    expect(find.text('\$45230.50'), findsOneWidget);
  });

  testWidgets('affiche une flèche verte pour une variation positive',
      (tester) async {
    final crypto = Crypto(
      id: 'bitcoin',
      name: 'Bitcoin',
      symbol: 'btc',
      currentPrice: 45000.0,
      priceChangePercentage24h: 2.4,
      lastUpdated: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(wrap('btc', [crypto]));
    await tester.pump();

    final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_drop_up));
    expect(icon.color, Colors.green);
    expect(find.text('2.4 %'), findsOneWidget);
  });

  testWidgets('affiche une flèche rouge pour une variation négative',
      (tester) async {
    final crypto = Crypto(
      id: 'bnb',
      name: 'BNB',
      symbol: 'bnb',
      currentPrice: 892.0,
      priceChangePercentage24h: -1.8,
      lastUpdated: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(wrap('bnb', [crypto]));
    await tester.pump();

    final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_drop_down));
    expect(icon.color, Colors.red);
    expect(find.text('1.8 %'), findsOneWidget);
  });

  testWidgets("n'affiche aucune icône de variation si null", (tester) async {
    final crypto = Crypto(
      id: 'tether',
      name: 'Tether',
      symbol: 'usdt',
      currentPrice: 1.0,
      lastUpdated: DateTime(2026, 1, 1),
      // priceChangePercentage24h absent
    );

    await tester.pumpWidget(wrap('usdt', [crypto]));
    await tester.pump();

    expect(find.byIcon(Icons.arrow_drop_up), findsNothing);
    expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
  });

  testWidgets('affiche "?" comme initiale si symbole vide', (tester) async {
    final crypto = Crypto(
      id: 'unknown',
      name: 'Unknown',
      symbol: '',
      currentPrice: 1.0,
      lastUpdated: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(wrap('', [crypto]));
    await tester.pump();

    expect(find.text('?'), findsOneWidget);
  });
}