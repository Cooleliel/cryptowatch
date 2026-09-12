import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/widgets/crypto_card.dart';
import 'package:flutter/material.dart';

class MarketListScreen extends StatelessWidget {
  final List<Crypto> cryptos;

  const MarketListScreen({super.key, required this.cryptos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cryptowatch')),
      body: ListView.builder(
        itemCount: cryptos.length,
        itemBuilder: (context, index) {
          return CryptoCard(crypto: cryptos[index]);
        },
      ),
    );
  }
}
