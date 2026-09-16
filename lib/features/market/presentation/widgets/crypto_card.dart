import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cryptowatch/app/theme/app_colors.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/crypto_flash_provider.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';
import 'package:cryptowatch/features/watchlist/presentation/providers/favorites_provider.dart';

/// Carte d'une crypto dans la liste du marché (Design moderne trading).
class CryptoCard extends ConsumerWidget {
  const CryptoCard({super.key, required this.symbol, this.onTap});

  final String symbol;
  final VoidCallback? onTap;

  static const List<Color> _palette = [
    Color(0xFFF7931A), // BTC Orange
    Color(0xFF627EEA), // ETH Blue
    Color(0xFF26A17B), // USDT Green
    Color(0xFFF0B90B), // BNB Yellow
    Color(0xFF9945FF), // SOL Purple
    Color(0xFF0033AD), // ADA Blue
    Color(0xFFE6007A), // DOT Pink
  ];

  Color _avatarColor() {
    final index = symbol.hashCode.abs() % _palette.length;
    return _palette[index];
  }

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
        ? AppColors.textSecondary
        : (isPositive ? AppColors.gain : AppColors.loss);

    final bool isFavorite = ref.watch(
      favoritesProvider.select((Set<String> ids) => ids.contains(crypto.id)),
    );

    final flashOverlay = switch (flash) {
      FlashState.up => Colors.green.withAlpha(45),
      FlashState.down => Colors.red.withAlpha(45),
      FlashState.none => Colors.transparent,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          key: Key('crypto-card-surface-${crypto.id}'),
          duration: const Duration(milliseconds: 250),
          color: flashOverlay,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _avatarColor().withAlpha(25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _avatarColor().withAlpha(60),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        symbol.isNotEmpty ? symbol[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: _avatarColor(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                symbol.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '/ USD',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            crypto.name,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${crypto.currentPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (variation != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isPositive
                                  ? AppColors.gainPill
                                  : AppColors.lossPill,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPositive
                                      ? Icons.arrow_drop_up
                                      : Icons.arrow_drop_down,
                                  color: variationColor,
                                  size: 16,
                                ),
                                Text(
                                  '${variation.abs().toStringAsFixed(1)} %',
                                  style: TextStyle(
                                    color: variationColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      key: Key('favorite-toggle-${crypto.id}'),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: () => ref
                          .read(favoritesProvider.notifier)
                          .toggleFavorite(crypto.id),
                      icon: Icon(
                        isFavorite ? Icons.star : Icons.star_border,
                        color: isFavorite
                            ? AppColors.star
                            : AppColors.textTertiary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final _sentinel = Crypto(
  id: '__sentinel__',
  name: '',
  symbol: '',
  currentPrice: 0,
  lastUpdated: DateTime(0),
);
