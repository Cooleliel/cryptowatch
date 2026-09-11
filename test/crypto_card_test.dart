import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/widgets/crypto_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('affiche le nom, le symbole et le prix formaté', (tester) async {
    final crypto = Crypto(
      id: 'bitcoin',
      name: 'Bitcoin',
      symbol: 'btc',
      currentPrice: 45230.5,
      lastUpdated: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(wrap(CryptoCard(crypto: crypto)));

    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.text('BTC'), findsOneWidget);
    expect(find.text('\$45230.50'), findsOneWidget);
  });

  testWidgets('affiche une flèche verte pour une variation positive', (tester) async {
    final crypto = Crypto(
      id: 'bitcoin', name: 'Bitcoin', symbol: 'btc',
      currentPrice: 45000.0, priceChangePercentage24h: 2.4,
      lastUpdated: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(wrap(CryptoCard(crypto: crypto)));

    final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_drop_up));
    expect(icon.color, Colors.green);
    expect(find.text('2.4 %'), findsOneWidget);
  });

  testWidgets('affiche une flèche rouge pour une variation négative', (tester) async {
    final crypto = Crypto(
      id: 'bnb', name: 'BNB', symbol: 'bnb',
      currentPrice: 892.0, priceChangePercentage24h: -1.8,
      lastUpdated: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(wrap(CryptoCard(crypto: crypto)));

    final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_drop_down));
    expect(icon.color, Colors.red);
    expect(find.text('1.8 %'), findsOneWidget);
  });

  testWidgets('n\'affiche aucune icône de variation si null', (tester) async {
    final crypto = Crypto(
      id: 'tether', name: 'Tether', symbol: 'usdt',
      currentPrice: 1.0, lastUpdated: DateTime(2026, 1, 1),
      // priceChangePercentage24h absent
    );

    await tester.pumpWidget(wrap(CryptoCard(crypto: crypto)));

    expect(find.byIcon(Icons.arrow_drop_up), findsNothing);
    expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
  });

  testWidgets('affiche "?" comme initiale si symbole vide', (tester) async {
    final crypto = Crypto(
      id: 'unknown', name: 'Unknown', symbol: '',
      currentPrice: 1.0, lastUpdated: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(wrap(CryptoCard(crypto: crypto)));

    expect(find.text('?'), findsOneWidget);
  });
}