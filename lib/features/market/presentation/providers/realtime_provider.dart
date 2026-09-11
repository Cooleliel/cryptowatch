import 'package:cryptowatch/features/market/data/realtime_service.dart';
import 'package:cryptowatch/features/market/domain/binance_ticker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//** Fournit une instance du service en temps réel */
final Provider<RealtimeService>
realtimeServiceProvider = Provider<RealtimeService>((Ref ref) {
  final RealtimeService service = RealtimeService()
    ..start(); //** Démarre le service en établissant une connexion WebSocket et en écoutant les messages entrants */
  ref.onDispose(
    service.dispose,
  ); //** Planifie la libération des ressources du service lorsque le provider est supprimé */
  return service; //** Retourne l'instance du service en temps réel */
});

//** Fournit un flux de données des tickers Binance */
final StreamProvider<BinanceTicker>
tickerStreamProvider = StreamProvider<BinanceTicker>((Ref ref) {
  final RealtimeService service = ref.watch(
    realtimeServiceProvider,
  ); //** Récupère l'instance du service en temps réel à partir du provider */
  return service
      .tickers; //** Retourne le flux de données des tickers Binance à partir du service en temps réel */
});
