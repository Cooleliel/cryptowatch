import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/widgets/crypto_card.dart';

void main() {
  Widget wrap(Widget child) => ProviderScope(
    child: MaterialApp(home: Scaffold(body: child)),
  );

  Crypto makeCrypto({
    String id = 'bitcoin',
    String name = 'Bitcoin',
    String symbol = 'btc',
    double price = 45000.0,
    double? variation,
  }) {
    return Crypto(
      id: id,
      name: name,
      symbol: symbol,
      currentPrice: price,
      priceChangePercentage24h: variation,
      lastUpdated: DateTime(2026, 1, 1),
    );
  }

  testWidgets('affiche le nom, le symbole et le prix formaté', (tester) async {
    await tester.pumpWidget(
      wrap(CryptoCard(crypto: makeCrypto(price: 45230.5))),
    );

    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.text('BTC'), findsOneWidget);
    expect(find.text('\$45230.50'), findsOneWidget);
  });

  testWidgets('affiche une flèche verte pour une variation positive', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(CryptoCard(crypto: makeCrypto(variation: 2.4))),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_drop_up));
    expect(icon.color, Colors.green);
    expect(find.text('2.4 %'), findsOneWidget);
  });

  testWidgets('affiche une flèche rouge pour une variation négative', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        CryptoCard(
          crypto: makeCrypto(
            id: 'bnb',
            name: 'BNB',
            symbol: 'bnb',
            variation: -1.8,
          ),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_drop_down));
    expect(icon.color, Colors.red);
    expect(find.text('1.8 %'), findsOneWidget);
  });

  testWidgets("n'affiche aucune icône de variation si null", (tester) async {
    await tester.pumpWidget(
      wrap(
        CryptoCard(
          crypto: makeCrypto(
            id: 'tether',
            name: 'Tether',
            symbol: 'usdt',
            price: 1.0,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_drop_up), findsNothing);
    expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
  });

  testWidgets('affiche "?" comme initiale si symbole vide', (tester) async {
    await tester.pumpWidget(
      wrap(
        CryptoCard(
          crypto: makeCrypto(
            id: 'unknown',
            name: 'Unknown',
            symbol: '',
            price: 1.0,
          ),
        ),
      ),
    );

    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('déclenche onTap au tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(CryptoCard(crypto: makeCrypto(), onTap: () => tapped = true)),
    );

    await tester.tap(find.text('Bitcoin'));
    expect(tapped, isTrue);
  });

  testWidgets("l'étoile toggle le statut favori", (tester) async {
    await tester.pumpWidget(wrap(CryptoCard(crypto: makeCrypto())));

    expect(find.byIcon(Icons.star_border), findsOneWidget);

    await tester.tap(find.byKey(const Key('favorite-toggle-bitcoin')));
    await tester.pump();
    expect(find.byIcon(Icons.star), findsOneWidget);

    await tester.tap(find.byKey(const Key('favorite-toggle-bitcoin')));
    await tester.pump();
    expect(find.byIcon(Icons.star_border), findsOneWidget);
  });
}
