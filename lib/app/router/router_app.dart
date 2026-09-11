import 'package:cryptowatch/app/widgets/app_shell.dart';
import 'package:cryptowatch/features/market/presentation/screens/market_screen.dart';
import 'package:cryptowatch/features/watchlist/presentation/screens/watchlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract class RouteNames {
  static const String market = 'marche';
  static const String watchlist = 'watchlist';
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return AppShell(navigationShell: navigationShell);
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/',
                name: RouteNames.market,
                builder: (BuildContext context, GoRouterState state) {
                  return const MarketScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/watchlist',
                name: RouteNames.watchlist,
                builder: (BuildContext context, GoRouterState state) {
                  return const WatchlistScreen();
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
