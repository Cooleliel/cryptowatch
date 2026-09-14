import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/screens/market_list_screen.dart';
import 'package:cryptowatch/features/market/presentation/screens/watchlist_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final List<Crypto> cryptos;

  const HomeScreen({super.key, required this.cryptos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cryptowatch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WatchlistScreen(cryptos: cryptos),
                ),
              );
            },
          ),
        ],
      ),
      body: MarketListScreen(cryptos: cryptos),
    );
  }
}
