/// Un point de la courbe : instant + prix en USD.
/// Dart pur, sans Flutter ni package HTTP.
class PricePoint {
  const PricePoint({required this.time, required this.price});

  final DateTime time;
  final double price;

  /// CoinGecko envoie `[timestamp_ms, prix]`.
  factory PricePoint.fromCoinGeckoPair(List<dynamic> pair) {
    if (pair.length < 2 || pair[0] is! num || pair[1] is! num) {
      throw const FormatException(
        'Point de prix CoinGecko invalide (attendu [timestamp, prix])',
      );
    }

    return PricePoint(
      time: DateTime.fromMillisecondsSinceEpoch((pair[0] as num).toInt()),
      price: (pair[1] as num).toDouble(),
    );
  }
}
