import 'package:flutter/material.dart';

abstract class AppTheme {
  static const Color _seed = Color(0xFFF7931A);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: _seed),
      appBarTheme: AppBarTheme(centerTitle: true),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seed,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(centerTitle: true),
    );
  }
}
