import 'package:flutter_riverpod/legacy.dart';

import 'package:cryptowatch/features/market/presentation/providers/market_filter_state.dart';

final marketFilterProvider =
    StateNotifierProvider<MarketFilterNotifier, MarketFilterState>((ref) {
      return MarketFilterNotifier();
    });

class MarketFilterNotifier extends StateNotifier<MarketFilterState> {
  MarketFilterNotifier() : super(const MarketFilterState());

  /// Filtre la liste affichée par nom ou symbole.
  void setQuery(String query) {
    if (state.query == query) return;
    state = state.copyWith(query: query);
  }

  /// Active un critère de tri. Un second tap sur le même critère inverse l'ordre.
  void setSortField(MarketSortField field) {
    if (state.sortField == field) {
      state = state.copyWith(sortDescending: !state.sortDescending);
      return;
    }
    state = state.copyWith(sortField: field, sortDescending: true);
  }
}