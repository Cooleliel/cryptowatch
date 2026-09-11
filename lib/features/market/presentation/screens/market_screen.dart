import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_state.dart';
import 'package:cryptowatch/features/market/presentation/widgets/crypto_card.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(marketProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('CryptoWatch')),
      body: switch (state) {
        MarketLoading() => const _LoadingView(),
        MarketError(:final message) => _ErrorView(
            message: message,
            onRetry: () => ref.read(marketProvider.notifier).retry(),
          ),
        MarketLoaded(:final cryptos) => cryptos.isEmpty
            ? const Center(child: Text('Aucune crypto trouvée'))
            : const _LoadedMarketView(),
      },
    );
  }
}

class _LoadedMarketView extends ConsumerWidget {
  const _LoadedMarketView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(marketProvider);
    if (state is! MarketLoaded) return const SizedBox.shrink();

    final visible = state.visibleCryptos;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            key: const Key('market-search-field'),
            textInputAction: TextInputAction.search,
            onChanged: ref.read(marketProvider.notifier).setQuery,
            decoration: const InputDecoration(
              hintText: 'Rechercher un nom ou un symbole',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const _SortBar(),
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
  const _SortBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(marketProvider);
    if (state is! MarketLoaded) return const SizedBox.shrink();

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
            state: state,
          ),
          _SortChip(
            key: const Key('market-sort-variation'),
            label: 'Variation',
            field: MarketSortField.variation,
            state: state,
          ),
          _SortChip(
            key: const Key('market-sort-market-cap'),
            label: 'Cap',
            field: MarketSortField.marketCap,
            state: state,
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
    required this.state,
  });

  final String label;
  final MarketSortField field;
  final MarketLoaded state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = state.sortField == field;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (selected) ...[
            const SizedBox(width: 4),
            Icon(
              state.sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
              size: 16,
            ),
          ],
        ],
      ),
      selected: selected,
      onSelected: (_) => ref.read(marketProvider.notifier).setSortField(field),
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
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
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