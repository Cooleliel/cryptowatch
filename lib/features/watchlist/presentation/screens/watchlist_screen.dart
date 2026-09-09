import 'package:flutter/material.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ma watchlist')),
      body: const Center(child: Text('Watchlist des cryptomonnaies')),
    );
  }
}
