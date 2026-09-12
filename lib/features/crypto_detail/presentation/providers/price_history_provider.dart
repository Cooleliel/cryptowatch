import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;

import 'package:cryptowatch/features/crypto_detail/data/repositories/price_history_repository.dart';
import 'package:cryptowatch/features/crypto_detail/presentation/providers/price_history_state.dart';
import 'package:cryptowatch/shared/errors/app_exception.dart';
import 'package:cryptowatch/shared/logging/app_logger.dart';
import 'package:cryptowatch/shared/logging/app_logger_provider.dart';

final priceHistoryRepositoryProvider = Provider<PriceHistoryRepository>((ref) {
  return PriceHistoryRepository(http.Client(), log: ref.read(appLogProvider));
});

final priceHistoryProvider = StateNotifierProvider.autoDispose
    .family<PriceHistoryNotifier, PriceHistoryState, String>((ref, coinId) {
      return PriceHistoryNotifier(
        ref.read(priceHistoryRepositoryProvider),
        coinId,
        log: ref.read(appLogProvider),
      );
    });

class PriceHistoryNotifier extends StateNotifier<PriceHistoryState> {
  PriceHistoryNotifier(
    this._repository,
    this._coinId, {
    this.log = defaultAppLog,
  }) : super(const PriceHistoryLoading()) {
    _load();
  }

  final PriceHistoryRepository _repository;
  final String _coinId;

  /// Ou partent les traces. Aucune erreur n'est avalee sans passer par ici.
  final AppLog log;

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
    } on AppException catch (error, stackTrace) {
      log(
        'Chargement de l\'historique echoue ($_coinId)',
        error: error,
        stackTrace: stackTrace,
      );
      state = PriceHistoryError(_messageFor(error));
    } catch (error, stackTrace) {
      // Filet de securite : le repository ne devrait laisser sortir que des
      // AppException. Si on arrive ici c'est un bug - il doit etre trace,
      // jamais avale.
      log(
        'Erreur inattendue au chargement de l\'historique ($_coinId)',
        error: error,
        stackTrace: stackTrace,
      );
      state = const PriceHistoryError('Une erreur inattendue est survenue.');
    }
  }

  Future<void> retry() => _load();
}

/// Le `switch` est exhaustif parce que [AppException] est `sealed` : ajouter un
/// type d'erreur sans traiter ce cas fait echouer la compilation.
String _messageFor(AppException error) {
  return switch (error) {
    RateLimitException() =>
      'Trop de requêtes vers CoinGecko. Réessaie dans un instant.',
    RequestTimeoutException() => 'La requête a pris trop de temps.',
    NetworkException() =>
      'Impossible de charger l\'historique. Vérifie ta connexion.',
    ServerException() => 'Le serveur CoinGecko a échoué.',
    InvalidDataException() => 'Données d\'historique illisibles.',
  };
}
