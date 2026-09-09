/// Immuable : les mises à jour passent par [copyWith] ou
/// [updateFromBinanceTicker], jamais de modification directe.
class Crypto {
  final String id;
  final String name;
  final String symbol;

  final double currentPrice;

  /// Absent des tickers Binance c'est pour cette raison qu'il est nullable.
  final String? imageUrl;

  final double? priceChangePercentage24h;
  final double? high24h;
  final double? low24h;

  /// Absent des tickers Binance (nécessite un fetch CoinGecko).
  final double? marketCap;
  final int? marketCapRank;

  /// Volume échangé sur 24h, exprimé en devise de cotation (ex: USDT),
  /// pas en actif de base — choix fait pour la lisibilité côté UI.
  final double? volume24h;

  final DateTime lastUpdated;

  const Crypto({
    required this.id,
    required this.name,
    required this.symbol,
    required this.currentPrice,
    this.imageUrl,
    this.priceChangePercentage24h,
    this.high24h,
    this.low24h,
    this.marketCap,
    this.marketCapRank,
    required this.lastUpdated,
    this.volume24h,
  });

  Crypto copyWith({
    String? id,
    String? name,
    String? symbol,
    double? currentPrice,
    String? imageUrl,
    double? priceChangePercentage24h,
    double? high24h,
    double? low24h,
    double? marketCap,
    int? marketCapRank,
    DateTime? lastUpdated,
    double? volume24h,
  }) {
    return Crypto(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      currentPrice: currentPrice ?? this.currentPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      priceChangePercentage24h:
          priceChangePercentage24h ?? this.priceChangePercentage24h,
      high24h: high24h ?? this.high24h,
      low24h: low24h ?? this.low24h,
      marketCap: marketCap ?? this.marketCap,
      marketCapRank: marketCapRank ?? this.marketCapRank,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      volume24h: volume24h ?? this.volume24h,
    );
  }
  
  /// ces methodes sont utilisées pour parser les données de l'API CoinGecko, 
  /// qui peut renvoyer des nombres sous forme de String ou de num.
  static double? _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value); // sécurité si l'API change
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  /// Construit un [Crypto] à partir d'une entrée de la réponse
  /// `/coins/markets` de CoinGecko.
  factory Crypto.fromCoinGeckoJson(Map<String, dynamic> json) {
    if (json['id'] is! String || json['name'] is! String ||
        json['symbol'] is! String || json['current_price'] is! num) {
      throw FormatException('Champ requis manquant ou de type invalide dans le JSON CoinGecko');
    }
    return Crypto(
      id: json['id'],
      name: json['name'],
      symbol: (json['symbol'] as String).toLowerCase(),
      currentPrice: (json['current_price'] as num).toDouble(),
      imageUrl: json['image'] is String ? json['image'] : null,
      priceChangePercentage24h: _parseDouble(json['price_change_percentage_24h']),
      high24h: _parseDouble(json['high_24h']),
      low24h: _parseDouble(json['low_24h']),
      marketCap: _parseDouble(json['market_cap']),
      marketCapRank: _parseInt(json['market_cap_rank']),
      lastUpdated: json['last_updated'] is String
          ? DateTime.tryParse(json['last_updated']) ?? DateTime.now()
          : DateTime.now(),
      volume24h: _parseDouble(json['total_volume']),
    );
  }

  /// Cette methode est utilisée pour parser les données de l'API Binance, 
  /// qui renvoie des nombres sous forme de String ou de num.
  static double? _parseBinanceDouble(dynamic value) {
    if (value is String) return double.tryParse(value);
    if (value is num) return value.toDouble();
    return null;
  }

  /// Binance ne fournit ni id, ni name, ni image : cette méthode met à
  /// jour une instance existante plutôt que d'en créer une nouvelle.

  Crypto updateFromBinanceTicker(Map<String, dynamic> json) {
    return copyWith(
      currentPrice: _parseBinanceDouble(json['c']),
      priceChangePercentage24h: _parseBinanceDouble(json['P']),
      high24h: _parseBinanceDouble(json['h']),
      low24h: _parseBinanceDouble(json['l']),
      volume24h: _parseBinanceDouble(json['q']),
      lastUpdated: json['E'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['E'])
          : null,
    );
  }
}
