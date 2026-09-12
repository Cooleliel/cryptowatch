import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      appBar: AppBar(title: const Text('CryptoWatch')),
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
  /// (sealed) : un nouveau type ajouté dans shared/errors force la mise à
  /// jour de ce switch. Le cas `_` couvre uniquement une erreur qui ne
  /// serait pas une AppException (filet de sécurité, ne devrait pas arriver
  /// si le contrat de MarketRepository est respecté).
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
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            key: const Key('market-search-field'),
            textInputAction: TextInputAction.search,
            onChanged: ref.read(marketFilterProvider.notifier).setQuery,
            decoration: const InputDecoration(
              hintText: 'Rechercher un nom ou un symbole',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        _SortBar(filter: filter),
        Expanded(
          child: visible.isEmpty
              ? const Center(child: Text('Aucune crypto trouvée'))
              : ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, index) =>
                      CryptoCard(crypto: visible[index]),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _SortChip(
            key: const Key('market-sort-price'),
            label: 'Prix',
            field: MarketSortField.price,
            filter: filter,
          ),
          _SortChip(
            key: const Key('market-sort-variation'),
            label: 'Variation',
            field: MarketSortField.variation,
            filter: filter,
          ),
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
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (selected) ...[
            const SizedBox(width: 4),
            Icon(
              filter.sortDescending
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              size: 16,
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
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement du marché...'),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger les cours',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}