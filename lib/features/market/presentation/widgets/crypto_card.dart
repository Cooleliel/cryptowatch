<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';

class CryptoCard extends StatelessWidget {
  const CryptoCard({super.key, required this.crypto, this.onTap});

  final Crypto crypto;
  final VoidCallback? onTap;

  // Palette fixe pour un avatar coloré déterministe par crypto,
  // sans dépendre d'une image (souvent absente côté Binance).
  static const List<Color> _palette = [
    Color(0xFFF7931A), // orange (Bitcoin-like)
    Color(0xFF627EEA), // bleu (Ethereum-like)
    Color(0xFF26A17B), // vert (Tether-like)
    Color(0xFFF0B90B), // jaune (BNB-like)
    Color(0xFF9945FF), // violet (Solana-like)
  ];

  Color _avatarColor() {
    final index = crypto.symbol.hashCode.abs() % _palette.length;
    return _palette[index];
  }

  @override
  Widget build(BuildContext context) {
    final variation = crypto.priceChangePercentage24h;
    final isPositive = (variation ?? 0) >= 0;
    final variationColor = variation == null
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : (isPositive ? Colors.green : Colors.red);

    return Material(
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
                  crypto.symbol.isNotEmpty
                      ? crypto.symbol[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
=======
import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/favorites/favorites_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CryptoCard extends StatelessWidget {
  final Crypto crypto;

  const CryptoCard({super.key, required this.crypto});

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.select<FavoritesCubit, bool>(
      (cubit) => cubit.isFavorite(crypto.id),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: InkWell(
        onTap: () {
          // Navigation detail au détail crypto si un écran est fourni plus tard.
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (crypto.imageUrl != null)
                CircleAvatar(
                  backgroundImage: NetworkImage(crypto.imageUrl!),
                  radius: 24,
                )
              else
                const CircleAvatar(
                  child: Icon(Icons.currency_bitcoin),
                  radius: 24,
                ),
>>>>>>> 419d60a (T-09a: watchlist - favoris et écran dédié)
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crypto.name,
<<<<<<< HEAD
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      crypto.symbol.toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
=======
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      crypto.symbol.toUpperCase(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\${crypto.currentPrice.toStringAsFixed(2)} USD',
>>>>>>> 419d60a (T-09a: watchlist - favoris et écran dédié)
                    ),
                  ],
                ),
              ),
<<<<<<< HEAD
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
=======
              GestureDetector(
                onTap: () {
                  context.read<FavoritesCubit>().toggleFavorite(crypto.id);
                },
                child: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? Colors.amber : Colors.grey,
                  size: 30,
                ),
>>>>>>> 419d60a (T-09a: watchlist - favoris et écran dédié)
              ),
            ],
          ),
        ),
      ),
    );
  }
}
