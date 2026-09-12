import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/crypto_flash_provider.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';

/// Carte d'une crypto dans la liste du marché.
///
/// **Architecture T-08b — granularité de rebuild**
///
/// La carte observe [marketProvider] via un `select` sur son propre symbole,
/// et non la liste entière. Conséquence : seule la carte dont le prix change
/// se redessine. Les 49 autres ne bougent pas, même si le provider émet un
/// nouvel état.
///
/// Sans ce découpage, chaque tick Binance forçait le rebuild de toutes les
/// cartes visibles, car `_LoadedMarketView` re-construisait toute la
/// `ListView` à chaque mise à jour du state.
///
/// **Flash vert / rouge**
///
/// Chaque carte possède sa propre instance de [CryptoFlashNotifier]
/// (via `cryptoFlashProvider(symbol)`). Quand [_watchCrypto] détecte un
/// nouveau prix, il appelle `trigger`, qui :
///   1. compare avec le prix précédent mémorisé dans le notifier,
///   2. positionne [FlashState.up] ou [FlashState.down],
///   3. programme l'extinction après [flashDuration] (600 ms).
///
/// **Pas de flash au premier chargement**
///
/// Le premier appel à `trigger` mémorise le prix initial sans afficher de
/// fond coloré. Cela évite le flash parasite qui apparaîtrait sinon à
/// l'ouverture de l'écran, alors qu'aucune variation n'a encore eu lieu.
class CryptoCard extends ConsumerWidget {
  const CryptoCard({super.key, required this.symbol});

  /// Symbole Binance en minuscules (ex: 'btc', 'eth').
  ///
  /// La carte utilise le symbole — et non l'objet [Crypto] entier — pour
  /// cibler sa propre ligne dans [marketProvider] via `select`. Passer
  /// l'objet entier forcerait un rebuild dès que n'importe quel champ
  /// changerait, même si le prix, la variation et le nom restent identiques.
  final String symbol;

  // Palette fixe pour un avatar coloré déterministe par crypto,
  // sans dépendre d'une image (souvent absente côté Binance).
  static const List<Color> _palette = [
    Color(0xFFF7931A), // orange (Bitcoin-like)
    Color(0xFF627EEA), // bleu (Ethereum-like)
    Color(0xFF26A17B), // vert (Tether-like)
    Color(0xF0B90B00), // jaune (BNB-like)  — format ARGB, alpha=F0
    Color(0xFF9945FF), // violet (Solana-like)
  ];

  Color _avatarColor() {
    final index = symbol.hashCode.abs() % _palette.length;
    return _palette[index];
  }

  /// Lit la crypto correspondant à [symbol] dans [marketProvider] et
  /// déclenche le flash si le prix a changé.
  ///
  /// Le `select` limite le rebuild de cette carte aux seuls changements
  /// de l'objet `Crypto` associé à ce symbole. Si Binance met à jour BTC,
  /// seule la carte BTC entre dans `_watchCrypto`.
  Crypto? _watchCrypto(WidgetRef ref) {
    final crypto = ref.watch(
      marketProvider.select(
        (asyncValue) => asyncValue.value?.firstWhere(
          (c) => c.symbol == symbol,
          orElse: () => _sentinel,
        ),
      ),
    );

    // _sentinel indique que le symbole n'est pas dans la liste (après filtre
    // ou avant chargement). On retourne null : la carte ne s'affiche pas.
    if (crypto == null || identical(crypto, _sentinel)) return null;

    // Déclenche le flash (comparaison avec le prix précédent dans le notifier).
    ref.read(cryptoFlashProvider(symbol).notifier).trigger(crypto.currentPrice);

    return crypto;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crypto = _watchCrypto(ref);

    // Garde-fou : ne devrait pas arriver en usage normal car la liste est
    // construite à partir des symboles présents dans marketProvider.
    if (crypto == null) return const SizedBox.shrink();

    final FlashState flash = ref.watch(cryptoFlashProvider(symbol));

    final variation = crypto.priceChangePercentage24h;
    final isPositive = (variation ?? 0) >= 0;
    final variationColor = variation == null
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : (isPositive ? Colors.green : Colors.red);

    // Couleur de fond animée selon l'état flash.
    // AnimatedContainer gère la transition (200 ms par défaut) pour un
    // fondu entrant doux ; l'extinction à 600 ms produit également un
    // fondu sortant sans code supplémentaire.
    final flashColor = switch (flash) {
      FlashState.up => Colors.green.withAlpha(40),
      FlashState.down => Colors.red.withAlpha(40),
      FlashState.none => Colors.transparent,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: flashColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _avatarColor(),
              child: Text(
                symbol.isNotEmpty ? symbol[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crypto.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    symbol.toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${crypto.currentPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (variation != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: variationColor,
                        size: 18,
                      ),
                      Text(
                        '${variation.abs().toStringAsFixed(1)} %',
                        style: TextStyle(color: variationColor),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Objet sentinelle utilisé pour distinguer « symbole absent de la liste »
/// (firstWhere avec orElse) de `null` (provider pas encore chargé).
///
/// On évite ainsi une exception dans `select` quand le filtre de recherche
/// cache temporairement une crypto ou quand le provider charge.
final _sentinel = Crypto(
  id: '__sentinel__',
  name: '',
  symbol: '',
  currentPrice: 0,
  lastUpdated: DateTime(0),
);