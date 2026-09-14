import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_filter_provider.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_filter_state.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_provider.dart';

/// Liste affichée : filtrée puis triée à partir des données de [marketProvider].
///
/// Reste un [AsyncValue] pour propager loading/error du chargement réseau
/// jusqu'à l'écran, même si le filtre/tri lui-même ne peut pas échouer.
final visibleCryptosProvider = Provider<AsyncValue<List<Crypto>>>((ref) {
  final asyncCryptos = ref.watch(marketProvider);
  final filter = ref.watch(marketFilterProvider);

  return asyncCryptos.whenData((cryptos) {
    final needle = filter.query.trim().toLowerCase();
    final filtered = needle.isEmpty
        ? cryptos
        : cryptos
              .where(
                (crypto) =>
                    crypto.name.toLowerCase().contains(needle) ||
                    crypto.symbol.toLowerCase().contains(needle),
              )
              .toList();

    final field = filter.sortField;
    if (field == null) return filtered;

    final sorted = List<Crypto>.of(filtered);
    sorted.sort((a, b) {
      final av = _sortValue(a, field);
      final bv = _sortValue(b, field);
      if (av == null && bv == null) return 0;
      if (av == null) return 1;
      if (bv == null) return -1;
      final cmp = av.compareTo(bv);
      return filter.sortDescending ? -cmp : cmp;
    });
    return sorted;
  });
});

double? _sortValue(Crypto crypto, MarketSortField field) {
  return switch (field) {
    MarketSortField.price => crypto.currentPrice,
    MarketSortField.variation => crypto.priceChangePercentage24h,
    MarketSortField.marketCap => crypto.marketCap,
  };
}