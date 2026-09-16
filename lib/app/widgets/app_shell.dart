import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cryptowatch/app/theme/app_colors.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 64,
            backgroundColor: Colors.white,
            elevation: 0,
            indicatorColor: AppColors.primaryLight,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (int index) {
              return navigationShell.goBranch(index);
            },
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.show_chart_rounded, color: AppColors.textSecondary),
                selectedIcon: Icon(Icons.show_chart_rounded, color: AppColors.primary),
                label: 'Marché',
              ),
              NavigationDestination(
                icon: Icon(Icons.star_outline_rounded, color: AppColors.textSecondary),
                selectedIcon: Icon(Icons.star_rounded, color: AppColors.primary),
                label: 'Watchlist',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

