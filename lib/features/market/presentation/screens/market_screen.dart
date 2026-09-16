import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cryptowatch/app/router/router_app.dart';
import 'package:cryptowatch/app/theme/app_colors.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_filter_provider.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_filter_state.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';
import 'package:cryptowatch/features/market/presentation/providers/visible_cryptos_provider.dart';
import 'package:cryptowatch/features/market/presentation/widgets/crypto_card.dart';
import 'package:cryptowatch/shared/errors/app_exception.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCryptos = ref.watch(marketProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('CryptoWatch'),
        centerTitle: false,
        actions: [
          IconButton(
            key: const Key('open-alerts-button'),
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () => context.pushNamed(RouteNames.alerts),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: asyncCryptos.when(
        loading: () => const _LoadingView(),
        error: (error, _) => _ErrorView(
          message: _messageFor(error),
          onRetry: () => ref.invalidate(marketProvider),
        ),
        data: (_) => const _LoadedMarketView(),
      ),
    );
  }

  /// Traduit une panne en phrase lisible. Exhaustif sur [AppException]
  String _messageFor(Object error) => switch (error) {
    NetworkException() => 'Pas de connexion. Vérifie ton réseau.',
    RequestTimeoutException() =>
      'Le serveur met trop de temps à répondre. Réessaie.',
    RateLimitException() =>
      'Trop de requêtes envoyées. Réessaie dans une minute.',
    ServerException() => 'Le service est indisponible pour le moment.',
    InvalidDataException() => 'Réponse inattendue du service.',
    _ => 'Une erreur inattendue est survenue.',
  };
}

class _LoadedMarketView extends ConsumerWidget {
  const _LoadedMarketView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(visibleCryptosProvider).value ?? const [];
    final filter = ref.watch(marketFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              key: const Key('market-search-field'),
              textInputAction: TextInputAction.search,
              onChanged: ref.read(marketFilterProvider.notifier).setQuery,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'Rechercher un nom ou un symbole',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        _SortBar(filter: filter),
        const SizedBox(height: 4),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: AppColors.textSecondary.withAlpha(120),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Aucune crypto trouvée',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20, top: 4),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final crypto = visible[index];
                    return CryptoCard(
                      key: Key('crypto-card-${crypto.id}'),
                      symbol: crypto.symbol,
                      onTap: () => context.pushNamed(
                        RouteNames.cryptoDetail,
                        pathParameters: {'id': crypto.id},
                        extra: crypto,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SortBar extends ConsumerWidget {
  const _SortBar({required this.filter});

  final MarketFilterState filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _SortChip(
            key: const Key('market-sort-price'),
            label: 'Prix',
            field: MarketSortField.price,
            filter: filter,
          ),
          const SizedBox(width: 8),
          _SortChip(
            key: const Key('market-sort-variation'),
            label: 'Variation',
            field: MarketSortField.variation,
            filter: filter,
          ),
          const SizedBox(width: 8),
          _SortChip(
            key: const Key('market-sort-market-cap'),
            label: 'Cap',
            field: MarketSortField.marketCap,
            filter: filter,
          ),
        ],
      ),
    );
  }
}

class _SortChip extends ConsumerWidget {
  const _SortChip({
    super.key,
    required this.label,
    required this.field,
    required this.filter,
  });

  final String label;
  final MarketSortField field;
  final MarketFilterState filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = filter.sortField == field;
    return FilterChip(
      showCheckmark: false,
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.cardBorder,
          width: 1,
        ),
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          if (selected) ...[
            const SizedBox(width: 4),
            Icon(
              filter.sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
              size: 14,
              color: Colors.white,
            ),
          ],
        ],
      ),
      selected: selected,
      onSelected: (_) =>
          ref.read(marketFilterProvider.notifier).setSortField(field),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Chargement du marché...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.lossPill,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.loss,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Impossible de charger les cours',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
