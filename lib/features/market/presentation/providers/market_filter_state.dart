/// Critère de tri de la liste. `null` conserve l'ordre renvoyé par l'API.
enum MarketSortField { price, variation, marketCap }

class MarketFilterState {
  const MarketFilterState({
    this.query = '',
    this.sortField,
    this.sortDescending = true,
  });

  /// Texte saisi dans le champ de recherche.
  final String query;

  /// Critère actif. `null` : ordre de l'API.
  final MarketSortField? sortField;

  /// `true` : du plus grand au plus petit.
  final bool sortDescending;

  MarketFilterState copyWith({
    String? query,
    MarketSortField? sortField,
    bool? sortDescending,
    bool clearSortField = false,
  }) {
    return MarketFilterState(
      query: query ?? this.query,
      sortField: clearSortField ? null : (sortField ?? this.sortField),
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }
}