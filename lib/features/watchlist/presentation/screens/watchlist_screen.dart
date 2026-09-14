import 'package:cryptowatch/app/router/router_app.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';
import 'package:cryptowatch/features/market/presentation/widgets/crypto_card.dart';
import 'package:cryptowatch/features/watchlist/presentation/providers/favorites_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final cryptos = ref.watch(marketProvider).value ?? const <Crypto>[];
    final watchlist = cryptos.where((c) => favorites.contains(c.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Ma watchlist')),
      body: watchlist.isEmpty
          ? const Center(
              child: Text(
                "Touche l'étoile d'une crypto sur le marché pour la retrouver ici",
              ),
            )
          : ListView.builder(
              itemCount: watchlist.length,
              itemBuilder: (context, index) => CryptoCard(
                crypto: watchlist[index],
                onTap: () => context.pushNamed(
                  RouteNames.cryptoDetail,
                  pathParameters: {'id': watchlist[index].id},
                  extra: watchlist[index],
                ),
              ),
            ),
    );
  }
}
