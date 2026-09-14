import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/favorites/favorites_cubit.dart';
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
///
/// **Favoris (dev)**
///
/// La carte observe [FavoritesCubit] via `context.select` pour afficher
/// l'étoile de favori. Le tap bascule l'état favori sans rebuild global.
///
/// **Navigation (T-06)**
///
/// [onTap] ouvre la fiche détail de la crypto.
class CryptoCard extends ConsumerWidget {
  const CryptoCard({super.key, required this.symbol, this.onTap});

  /// Symbole Binance en minuscules (ex: 'btc', 'eth').
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

  /// Lit la crypto correspondant à [symbol] dans [marketProvider] et
  /// déclenche le flash si le prix a changé.
  Crypto? _watchCrypto(WidgetRef ref) {
    final crypto = ref.watch(
      marketProvider.select(
        (asyncValue) => asyncValue.value?.firstWhere(
          (c) => c.symbol == symbol,
          orElse: () => _sentinel,
        ),
      ),
    );

    if (crypto == null || identical(crypto, _sentinel)) return null;

    ref.read(cryptoFlashProvider(symbol).notifier).trigger(crypto.currentPrice);

    return crypto;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crypto = _watchCrypto(ref);

    if (crypto == null) return const SizedBox.shrink();

    final FlashState flash = ref.watch(cryptoFlashProvider(symbol));

    final variation = crypto.priceChangePercentage24h;
    final isPositive = (variation ?? 0) >= 0;
    final variationColor = variation == null
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : (isPositive ? Colors.green : Colors.red);
    final isFavorite = context.select<FavoritesCubit?, bool>(
      (cubit) => cubit?.isFavorite(crypto.id) ?? false,
    );

    final flashColor = switch (flash) {
      FlashState.up => Colors.green.withAlpha(40),
      FlashState.down => Colors.red.withAlpha(40),
      FlashState.none => Colors.transparent,
    };

    return AnimatedContainer(
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
                GestureDetector(
                  onTap: () {
                    context.read<FavoritesCubit?>()?.toggleFavorite(crypto.id);
                  },
                  child: Icon(
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

/// Objet sentinelle utilisé pour distinguer « symbole absent de la liste »
/// de `null` (provider pas encore chargé).
final _sentinel = Crypto(
  id: '__sentinel__',
  name: '',
  symbol: '',
  currentPrice: 0,
  lastUpdated: DateTime(0),
);