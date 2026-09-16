import 'package:cryptowatch/features/alerts/domain/price_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cryptowatch/app/theme/app_colors.dart';
import 'package:cryptowatch/features/alerts/presentation/providers/alerts_provider.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Maintient alertsProvider vivant en permanence (les providers Riverpod
    // sont paresseux) : la surveillance des seuils tourne quel que soit
    // l'écran affiché, pas seulement quand l'écran Alertes est ouvert.
    ref.listen(alertsProvider, (_, _) {});

    // Affiche chaque alerte déclenchée, où que soit l'utilisateur.
    ref.listen<AlertTriggeredEvent?>(alertEventProvider, (previous, next) {
      if (next == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔔 ${next.message}'),
          duration: const Duration(seconds: 5),
        ),
      );
    });

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
                icon: Icon(
                  Icons.show_chart_rounded,
                  color: AppColors.textSecondary,
                ),
                selectedIcon: Icon(
                  Icons.show_chart_rounded,
                  color: AppColors.primary,
                ),
                label: 'Marché',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.star_outline_rounded,
                  color: AppColors.textSecondary,
                ),
                selectedIcon: Icon(
                  Icons.star_rounded,
                  color: AppColors.primary,
                ),
                label: 'Watchlist',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
