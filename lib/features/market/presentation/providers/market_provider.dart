import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:cryptowatch/features/market/data/repositories/market_repository.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_state.dart';

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return MarketRepository(http.Client());
});

final marketProvider = StateNotifierProvider<MarketNotifier, MarketState>((
  ref,
) {
  return MarketNotifier(ref.read(marketRepositoryProvider));
});

class MarketNotifier extends StateNotifier<MarketState> {
  MarketNotifier(this._repository) : super(const MarketLoading()) {
    _loadCryptos();
  }

  final MarketRepository _repository;

  Future<void> _loadCryptos() async {
    state = const MarketLoading();
    try {
      final cryptos = await _repository.fetchTopCryptos();
      state = MarketLoaded(cryptos);
    } catch (_) {
      state = const MarketError(
        'Impossible de charger les cours. Vérifie ta connexion.',
      );
    }
  }

  Future<void> retry() => _loadCryptos();

  /// Filtre la liste déjà chargée. Sans effet hors de [MarketLoaded].
  void setQuery(String query) {
    final current = state;
    if (current is! MarketLoaded) return;
    if (current.query == query) return;
    state = current.copyWith(query: query);
  }

  /// Active un critère de tri. Un second tap sur le même critère inverse l'ordre.
  void setSortField(MarketSortField field) {
    final current = state;
    if (current is! MarketLoaded) return;
    if (current.sortField == field) {
      state = current.copyWith(sortDescending: !current.sortDescending);
      return;
    }
    state = current.copyWith(sortField: field, sortDescending: true);
  }
}
