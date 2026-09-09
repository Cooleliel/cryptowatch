import 'package:flutter/material.dart';

import 'package:cryptowatch/app/theme/app_colors.dart';
import 'package:cryptowatch/features/crypto_detail/presentation/screens/crypto_detail_screen.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CryptoWatch',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
      ),
      home: const CryptoDetailScreen(),
    );
  }
}
