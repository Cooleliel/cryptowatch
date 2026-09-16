import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cryptowatch/app/router/router_app.dart';
import 'package:cryptowatch/app/theme/app_colors.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';
import 'package:cryptowatch/features/market/presentation/widgets/crypto_card.dart';
import 'package:cryptowatch/features/watchlist/presentation/providers/favorites_provider.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final cryptos = ref.watch(marketProvider).value ?? const <Crypto>[];
    final watchlist = cryptos.where((c) => favorites.contains(c.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Ma watchlist'), centerTitle: false),
      body: watchlist.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.star.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: AppColors.star,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Aucun favori pour le moment',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Touche l'étoile d'une crypto sur le marché pour la retrouver ici",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              itemCount: watchlist.length,
              itemBuilder: (context, index) {
                final Crypto crypto = watchlist[index];
                return CryptoCard(
                  key: Key('watchlist-card-${crypto.id}'),
                  symbol: crypto.symbol,
                  onTap: () => context.pushNamed(
                    RouteNames.cryptoDetail,
                    pathParameters: <String, String>{'id': crypto.id},
                    extra: crypto,
                  ),
                );
              },
            ),
    );
  }
}
