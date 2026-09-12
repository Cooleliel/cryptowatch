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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crypto.name,
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
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  context.read<FavoritesCubit>().toggleFavorite(crypto.id);
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
    );
  }
}
