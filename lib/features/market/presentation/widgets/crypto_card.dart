import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/crypto_flash_provider.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';
import 'package:cryptowatch/features/watchlist/presentation/providers/favorites_provider.dart';

/// Carte d'une crypto dans la liste du marché.
///
/// **Architecture T-08b — granularité de rebuild**
/// La carte observe [marketProvider] via un `select` sur son propre symbole :
/// seule la carte dont le prix change se redessine, jamais la liste entière.
///
/// **Flash vert / rouge**
/// Chaque carte possède son instance de [CryptoFlashNotifier]
/// (`cryptoFlashProvider(symbol)`). Le déclenchement passe par `ref.listen`
/// (jamais pendant le build : modifier un provider observé en plein build
/// provoquerait un markNeedsBuild-during-build). Le premier prix reçu est
/// mémorisé sans flash (pas de fond coloré parasite au chargement).
///
/// **Favoris (T-09a)** : étoile branchée sur [favoritesProvider], avec
/// `select` — la carte ne se redessine que si SON statut favori change.
class CryptoCard extends ConsumerWidget {
  const CryptoCard({super.key, required this.symbol, this.onTap});

  /// Symbole en minuscules (ex: 'btc', 'eth').
  final String symbol;

  /// Appelé au tap sur la carte. `null` désactive l'ondulation et le tap.
  final VoidCallback? onTap;

  static const List<Color> _palette = [
    Color(0xFFF7931A),
    Color(0xFF627EEA),
    Color(0xFF26A17B),
    Color(0xFFF0B90B),
    Color(0xFF9945FF),
  ];

  Color _avatarColor() {
    final index = symbol.hashCode.abs() % _palette.length;
    return _palette[index];
  }

  /// Sélectionne la crypto de CETTE carte dans l'état du marché.
  Crypto? _selectCrypto(AsyncValue<List<Crypto>> asyncValue) {
    final crypto = asyncValue.value?.firstWhere(
      (c) => c.symbol == symbol,
      orElse: () => _sentinel,
    );
    if (crypto == null || identical(crypto, _sentinel)) return null;
    return crypto;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Déclenchement du flash HORS build : le listener s'exécute après la
    // mise à jour du provider, jamais pendant la construction de la carte.
    ref.listen<Crypto?>(marketProvider.select(_selectCrypto), (previous, next) {
      if (next != null) {
        ref
            .read(cryptoFlashProvider(symbol).notifier)
            .trigger(next.currentPrice);
      }
    });

    final crypto = ref.watch(marketProvider.select(_selectCrypto));
    if (crypto == null) return const SizedBox.shrink();

    final FlashState flash = ref.watch(cryptoFlashProvider(symbol));

    final variation = crypto.priceChangePercentage24h;
    final isPositive = (variation ?? 0) >= 0;
    final variationColor = variation == null
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : (isPositive ? Colors.green : Colors.red);

    final bool isFavorite = ref.watch(
      favoritesProvider.select((Set<String> ids) => ids.contains(crypto.id)),
    );

    final flashColor = switch (flash) {
      FlashState.up => Colors.green.withAlpha(40),
      FlashState.down => Colors.red.withAlpha(40),
      FlashState.none => Colors.transparent,
    };

    return AnimatedContainer(
      key: Key('crypto-card-surface-${crypto.id}'),
      duration: const Duration(milliseconds: 200),
      color: flashColor,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
                IconButton(
                  key: Key('favorite-toggle-${crypto.id}'),
                  onPressed: () => ref
                      .read(favoritesProvider.notifier)
                      .toggleFavorite(crypto.id),
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite ? Colors.amber : Colors.grey,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sentinelle : distingue « symbole absent de la liste » de « provider pas
/// encore chargé » (null).
final _sentinel = Crypto(
  id: '__sentinel__',
  name: '',
  symbol: '',
  currentPrice: 0,
  lastUpdated: DateTime(0),
);
