import 'package:cryptowatch/features/crypto_detail/domain/price_point.dart';

sealed class PriceHistoryState {
  const PriceHistoryState();
}

class PriceHistoryLoading extends PriceHistoryState {
  const PriceHistoryLoading();
}

class PriceHistoryError extends PriceHistoryState {
  const PriceHistoryError(this.message);

  final String message;
}

class PriceHistoryLoaded extends PriceHistoryState {
  const PriceHistoryLoaded(this.points);

  final List<PricePoint> points;

  List<double> get prices =>
      points.map((PricePoint point) => point.price).toList();
}
