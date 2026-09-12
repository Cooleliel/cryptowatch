import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:cryptowatch/features/market/data/repositories/market_repository.dart';
import 'package:cryptowatch/features/market/domain/binance_ticker.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';
import 'package:cryptowatch/features/market/presentation/providers/realtime_provider.dart';
import 'package:cryptowatch/shared/logging/app_logger_provider.dart';

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return MarketRepository(http.Client(), log: ref.read(appLogProvider));
});

/// T-04b (chargement REST) + T-08a (mise à jour temps réel).
///
/// N'expose plus query/tri (voir [MarketFilterNotifier]) : ce notifier ne
/// porte que les données brutes du marché.
class MarketNotifier extends AsyncNotifier<List<Crypto>> {
  @override
  Future<List<Crypto>> build() async {
    // Se réabonne au flux temps réel à chaque (re)build, donc aussi après un
    // retry (ref.invalidate) ; l'abonnement précédent est fermé automatiquement.
    final subscription = ref.listen<AsyncValue<BinanceTicker>>(
      tickerStreamProvider,
      (previous, next) => next.whenData(_applyTickerUpdate),
    );
    ref.onDispose(subscription.close);

    // Le repository (T-03b) ne laisse sortir que des AppException : elles
    // remontent telles quelles, AsyncNotifier les convertit en AsyncError.
    // Le message affiché à l'utilisateur est décidé dans market_screen.dart,
    // pas ici (presentation choisit le texte, pas data/provider).
    return ref.read(marketRepositoryProvider).fetchTopCryptos();
  }

  /// Applique un tick Binance à la crypto correspondante (matching par
  /// symbole). Sans effet si les données ne sont pas encore chargées.
  void _applyTickerUpdate(BinanceTicker ticker) {
    final currentCryptos = state.value;
    if (currentCryptos == null) return;

    state = AsyncData([
      for (final crypto in currentCryptos)
        if (crypto.symbol == ticker.symbol)
          crypto.updateFromBinanceTicker(ticker.raw)
        else
          crypto,
    ]);
  }
}

final marketProvider = AsyncNotifierProvider<MarketNotifier, List<Crypto>>(
  MarketNotifier.new,
);