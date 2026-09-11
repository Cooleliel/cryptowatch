import 'package:cryptowatch/features/market/domain/crypto.dart';

/// Critère de tri de la liste. `null` conserve l'ordre renvoyé par l'API.
enum MarketSortField { price, variation, marketCap }

sealed class MarketState {
  const MarketState();
}

class MarketLoading extends MarketState {
  const MarketLoading();
}

class MarketError extends MarketState {
  const MarketError(this.message);
  final String message;
}

class MarketLoaded extends MarketState {
  const MarketLoaded(
    this.cryptos, {
    this.query = '',
    this.sortField,
    this.sortDescending = true,
  });

  /// Liste brute renvoyée par l'API. La recherche ne la modifie jamais.
  final List<Crypto> cryptos;

  /// Texte saisi dans le champ de recherche.
  final String query;

  /// Critère actif. `null` : ordre de l'API.
  final MarketSortField? sortField;

  /// `true` : du plus grand au plus petit.
  final bool sortDescending;

  /// Filtre, puis tri. La liste brute [cryptos] reste inchangée.
  List<Crypto> get visibleCryptos {
    final needle = query.trim().toLowerCase();
    final filtered = needle.isEmpty
        ? cryptos
        : cryptos
            .where(
              (crypto) =>
                  crypto.name.toLowerCase().contains(needle) ||
                  crypto.symbol.toLowerCase().contains(needle),
            )
            .toList();

    final field = sortField;
    if (field == null) return filtered;

    final sorted = List<Crypto>.of(filtered);
    sorted.sort((a, b) {
      final av = _sortValue(a, field);
      final bv = _sortValue(b, field);
      if (av == null && bv == null) return 0;
      if (av == null) return 1;
      if (bv == null) return -1;
      final cmp = av.compareTo(bv);
      return sortDescending ? -cmp : cmp;
    });
    return sorted;
  }

  static double? _sortValue(Crypto crypto, MarketSortField field) {
    return switch (field) {
      MarketSortField.price => crypto.currentPrice,
      MarketSortField.variation => crypto.priceChangePercentage24h,
      MarketSortField.marketCap => crypto.marketCap,
    };
  }

  MarketLoaded copyWith({
    List<Crypto>? cryptos,
    String? query,
    MarketSortField? sortField,
    bool? sortDescending,
    bool clearSortField = false,
  }) {
    return MarketLoaded(
      cryptos ?? this.cryptos,
      query: query ?? this.query,
      sortField: clearSortField ? null : (sortField ?? this.sortField),
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }
}