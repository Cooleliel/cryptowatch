import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;

import 'package:cryptowatch/features/crypto_detail/data/repositories/price_history_repository.dart';
import 'package:cryptowatch/features/crypto_detail/presentation/providers/price_history_state.dart';

final priceHistoryRepositoryProvider = Provider<PriceHistoryRepository>((ref) {
  return PriceHistoryRepository(http.Client());
});

final priceHistoryProvider = StateNotifierProvider.family<
    PriceHistoryNotifier, PriceHistoryState, String>((ref, coinId) {
  return PriceHistoryNotifier(
    ref.read(priceHistoryRepositoryProvider),
    coinId,
  );
});

class PriceHistoryNotifier extends StateNotifier<PriceHistoryState> {
  PriceHistoryNotifier(this._repository, this._coinId)
      : super(const PriceHistoryLoading()) {
    _load();
  }

  final PriceHistoryRepository _repository;
  final String _coinId;

  Future<void> _load() async {
    state = const PriceHistoryLoading();
    try {
      final points = await _repository.fetchLast7Days(_coinId);
      if (points.length < 2) {
        state = const PriceHistoryError(
          'Pas assez de points pour tracer la courbe.',
        );
        return;
      }
      state = PriceHistoryLoaded(points);
    } catch (_) {
      state = const PriceHistoryError(
        'Impossible de charger l\'historique. Vérifie ta connexion.',
      );
    }
  }

  Future<void> retry() => _load();
}
