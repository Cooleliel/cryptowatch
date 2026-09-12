// ignore: unused_import
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cryptowatch/features/market/domain/binance_ticker.dart';
import 'package:cryptowatch/features/market/presentation/providers/realtime_provider.dart';
import 'package:flutter_riverpod/misc.dart';

/// À inclure dans le `ProviderScope` de tout widget test qui monte
/// `MarketScreen`, directement ou via l'app entière (smoke tests).
///
/// Sans cet override, `marketProvider` tente une vraie connexion WebSocket
/// vers Binance pendant le test, ce qui laisse un timer en attente après le
/// démontage du widget et fait échouer l'assertion `!timersPending` de
/// flutter_test.
List<Override> fakeRealtimeOverrides() => [
  tickerStreamProvider.overrideWith(
    (ref) => const Stream<BinanceTicker>.empty(),
  ),
];