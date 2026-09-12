import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/favorites/favorites_cubit.dart';
import 'package:cryptowatch/features/market/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  final sampleCryptos = [
    Crypto(
      id: 'bitcoin',
      name: 'Bitcoin',
      symbol: 'btc',
      currentPrice: 45000,
      lastUpdated: DateTime.now(),
    ),
    Crypto(
      id: 'ethereum',
      name: 'Ethereum',
      symbol: 'eth',
      currentPrice: 3000,
      lastUpdated: DateTime.now(),
    ),
  ];

  runApp(MainApp(cryptos: sampleCryptos));
}

class MainApp extends StatelessWidget {
  final List<Crypto> cryptos;

  const MainApp({super.key, required this.cryptos});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FavoritesCubit(),
      child: MaterialApp(
        home: HomeScreen(cryptos: cryptos),
      ),
    );
  }
}
