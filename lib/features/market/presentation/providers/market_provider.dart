import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:cryptowatch/features/market/data/repositories/market_repository.dart';
import 'package:cryptowatch/features/market/presentation/providers/market_state.dart';
import 'package:cryptowatch/shared/errors/app_exception.dart';
import 'package:cryptowatch/shared/logging/app_logger.dart';
import 'package:cryptowatch/shared/logging/app_logger_provider.dart';

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return MarketRepository(http.Client(), log: ref.read(appLogProvider));
});

final marketProvider = StateNotifierProvider<MarketNotifier, MarketState>((
  ref,
) {
  return MarketNotifier(
    ref.read(marketRepositoryProvider),
    log: ref.read(appLogProvider),
  );
});

class MarketNotifier extends StateNotifier<MarketState> {
  MarketNotifier(this._repository, {this.log = defaultAppLog})
    : super(const MarketLoading()) {
    _loadCryptos();
  }

  final MarketRepository _repository;

  /// Ou partent les traces. Aucune erreur n'est avalee sans passer par ici.
  final AppLog log;

  Future<void> _loadCryptos() async {
    state = const MarketLoading();
    try {
      final cryptos = await _repository.fetchTopCryptos();
      state = MarketLoaded(cryptos);
    } on AppException catch (error, stackTrace) {
      log('Chargement du marche echoue', error: error, stackTrace: stackTrace);
      state = MarketError(_messageFor(error));
    } catch (error, stackTrace) {
      // Filet de securite : le repository ne devrait laisser sortir que des
      // AppException. Si on arrive ici c'est un bug - il doit etre trace,
      // jamais avale.
      log(
        'Erreur inattendue au chargement du marche',
        error: error,
        stackTrace: stackTrace,
      );
      state = const MarketError('Une erreur inattendue est survenue.');
    }
  }

  /// Traduit une panne en phrase lisible.
  ///
  /// Le `switch` est exhaustif parce que [AppException] est `sealed` : le jour
  /// ou un sixieme type d'erreur sera ajoute, l'analyseur signalera cette
  /// methode tant qu'elle ne le traitera pas.
  String _messageFor(AppException error) {
    return switch (error) {
      NetworkException() => 'Pas de connexion. Verifie ton reseau.',
      RequestTimeoutException() =>
        'Le serveur met trop de temps a repondre. Reessaie.',
      RateLimitException() =>
        'Trop de requetes envoyees. Reessaie dans une minute.',
      ServerException() => 'Le service est indisponible pour le moment.',
      InvalidDataException() => 'Reponse inattendue du service.',
    };
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
