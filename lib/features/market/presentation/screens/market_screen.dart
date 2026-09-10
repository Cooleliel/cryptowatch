import 'package:flutter/material.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CryptoWatch')),
      body: const Center(child: Text('La liste du marché des cryptomonnaies')),
    );
  }
}
