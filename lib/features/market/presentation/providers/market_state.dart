import 'package:cryptowatch/features/market/domain/crypto.dart';

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
  const MarketLoaded(this.cryptos);
  final List<Crypto> cryptos;
}