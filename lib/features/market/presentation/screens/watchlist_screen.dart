import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/favorites/favorites_cubit.dart';
import 'package:cryptowatch/features/market/presentation/widgets/crypto_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WatchlistScreen extends StatelessWidget {
  final List<Crypto> cryptos;

  const WatchlistScreen({super.key, required this.cryptos});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesCubit>().state.favoriteIds;
    final watchlist = cryptos.where((crypto) => favorites.contains(crypto.id)).toList();

    if (watchlist.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Watchlist')),
        body: const Center(
          child: Text('Aucune crypto en favori pour l\'instant'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Watchlist')),
      body: ListView.builder(
        itemCount: watchlist.length,
        itemBuilder: (context, index) {
          return CryptoCard(crypto: watchlist[index]);
        },
      ),
    );
  }
}
