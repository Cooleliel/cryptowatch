import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/crypto_flash_provider.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';
import 'package:cryptowatch/features/market/presentation/widgets/crypto_card.dart';
import 'helpers/fake_realtime_overrides.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Crypto minimale réutilisée dans les tests.
Crypto _makeCrypto({
  String id = 'bitcoin',
  String name = 'Bitcoin',
  String symbol = 'btc',
  required double price,
  double? variation,
}) =>
    Crypto(
      id: id,
      name: name,
      symbol: symbol,
      currentPrice: price,
      priceChangePercentage24h: variation,
      lastUpdated: DateTime(2026, 1, 1),
    );

/// Notifier factice : renvoie une liste fixe sans faire de requête réseau.
///
/// Doit étendre [MarketNotifier] (et non AsyncNotifier directement) pour
/// être compatible avec le type attendu par `marketProvider.overrideWith`.
class _FakeMarketNotifier extends MarketNotifier {
  _FakeMarketNotifier(this._cryptos);
  final List<Crypto> _cryptos;

  @override
  Future<List<Crypto>> build() async => _cryptos;
}

/// Monte une [CryptoCard] dans un [ProviderScope] avec [marketProvider]
/// surchargé pour retourner [cryptos].
Widget _buildCard(String symbol, List<Crypto> cryptos) {
  return ProviderScope(
    overrides: [
      ...fakeRealtimeOverrides(),
      marketProvider.overrideWith(() => _FakeMarketNotifier(cryptos)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: CryptoCard(symbol: symbol),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests CryptoFlashNotifier (logique pure, sans widgets)
// ---------------------------------------------------------------------------

void main() {
  group('CryptoFlashNotifier —', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('état initial est FlashState.none', () {
      expect(container.read(cryptoFlashProvider('btc')), FlashState.none);
    });

    test('premier trigger ne produit pas de flash (pas de prix précédent)', () {
      container.read(cryptoFlashProvider('btc').notifier).trigger(50000);
      expect(container.read(cryptoFlashProvider('btc')), FlashState.none);
    });

    test('hausse → FlashState.up', () {
      container.read(cryptoFlashProvider('btc').notifier).trigger(50000);
      container.read(cryptoFlashProvider('btc').notifier).trigger(51000);
      expect(container.read(cryptoFlashProvider('btc')), FlashState.up);
    });

    test('baisse → FlashState.down', () {
      container.read(cryptoFlashProvider('btc').notifier).trigger(50000);
      container.read(cryptoFlashProvider('btc').notifier).trigger(49000);
      expect(container.read(cryptoFlashProvider('btc')), FlashState.down);
    });

    test('prix identique → pas de flash, état reste none', () {
      container.read(cryptoFlashProvider('btc').notifier).trigger(50000);
      container.read(cryptoFlashProvider('btc').notifier).trigger(50000);
      expect(container.read(cryptoFlashProvider('btc')), FlashState.none);
    });

    test("flash s'éteint après flashDuration", () async {
      container.read(cryptoFlashProvider('btc').notifier).trigger(50000);
      container.read(cryptoFlashProvider('btc').notifier).trigger(51000);

      expect(container.read(cryptoFlashProvider('btc')), FlashState.up);

      await Future<void>.delayed(
        flashDuration + const Duration(milliseconds: 50),
      );
      expect(container.read(cryptoFlashProvider('btc')), FlashState.none);
    });

    test('deux ticks dans la fenêtre → le flash repart proprement', () async {
      container.read(cryptoFlashProvider('btc').notifier).trigger(50000);
      container.read(cryptoFlashProvider('btc').notifier).trigger(51000); // timer T1
      container.read(cryptoFlashProvider('btc').notifier).trigger(52000); // T1 annulé, T2

      expect(container.read(cryptoFlashProvider('btc')), FlashState.up);

      await Future<void>.delayed(
        flashDuration + const Duration(milliseconds: 50),
      );
      expect(container.read(cryptoFlashProvider('btc')), FlashState.none);
    });

    test('instances indépendantes par symbole (btc ne pollue pas eth)', () {
      container.read(cryptoFlashProvider('btc').notifier).trigger(50000);
      container.read(cryptoFlashProvider('btc').notifier).trigger(51000);

      expect(container.read(cryptoFlashProvider('eth')), FlashState.none);
      expect(container.read(cryptoFlashProvider('btc')), FlashState.up);
    });
  });

  // ---------------------------------------------------------------------------
  // Tests CryptoCard (widget)
  // ---------------------------------------------------------------------------

  group('CryptoCard —', () {
    testWidgets('affiche le nom, le symbole et le prix formaté', (tester) async {
      final crypto = _makeCrypto(price: 45230.5);
      await tester.pumpWidget(_buildCard('btc', [crypto]));
      await tester.pump();

      expect(find.text('Bitcoin'), findsOneWidget);
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('\$45230.50'), findsOneWidget);
    });

    testWidgets('affiche une flèche verte pour une variation positive',
        (tester) async {
      final crypto = _makeCrypto(price: 45000, variation: 2.4);
      await tester.pumpWidget(_buildCard('btc', [crypto]));
      await tester.pump();

      final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_drop_up));
      expect(icon.color, Colors.green);
      expect(find.text('2.4 %'), findsOneWidget);
    });

    testWidgets('affiche une flèche rouge pour une variation négative',
        (tester) async {
      final crypto = _makeCrypto(
        id: 'bnb', name: 'BNB', symbol: 'bnb', price: 892, variation: -1.8,
      );
      await tester.pumpWidget(_buildCard('bnb', [crypto]));
      await tester.pump();

      final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_drop_down));
      expect(icon.color, Colors.red);
      expect(find.text('1.8 %'), findsOneWidget);
    });

    testWidgets("n'affiche aucune icône si variation est null", (tester) async {
      final crypto =
          _makeCrypto(price: 1.0, symbol: 'usdt', name: 'Tether', id: 'tether');
      await tester.pumpWidget(_buildCard('usdt', [crypto]));
      await tester.pump();

      expect(find.byIcon(Icons.arrow_drop_up), findsNothing);
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
    });

    testWidgets('affiche "?" comme initiale si symbole vide', (tester) async {
      final crypto =
          _makeCrypto(id: 'unknown', name: 'Unknown', symbol: '', price: 1);
      await tester.pumpWidget(_buildCard('', [crypto]));
      await tester.pump();

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets(
        'pas de flash au premier chargement (cryptoFlashProvider reste none)',
        (tester) async {
      // Le premier tick mémorise le prix initial sans déclencher de flash.
      // On vérifie cryptoFlashProvider directement via le container Riverpod.
      late ProviderContainer capturedContainer;
      final crypto = _makeCrypto(price: 50000);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...fakeRealtimeOverrides(),
            marketProvider.overrideWith(() => _FakeMarketNotifier([crypto])),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              capturedContainer = ProviderScope.containerOf(context);
              return MaterialApp(
                home: Scaffold(body: CryptoCard(symbol: 'btc')),
              );
            },
          ),
        ),
      );
      await tester.pump();

      expect(
        capturedContainer.read(cryptoFlashProvider('btc')),
        FlashState.none,
      );
    });
  });
}
