/// Représente une cryptomonnaie et ses données de marché.
///
/// Cet objet est immuable : toute mise à jour (prix, volume...) passe par
/// [copyWith] ou [updateFromBinanceTicker], qui retournent une nouvelle
/// instance plutôt que de modifier l'existante.
///
/// Deux sources de données alimentent ce modèle :
/// - CoinGecko (REST) fournit les données complètes via [fromCoinGeckoJson]
/// - Binance (WebSocket) fournit uniquement les mises à jour de prix en
///   temps réel via [updateFromBinanceTicker] — voir cette méthode pour
///   savoir pourquoi elle ne peut pas créer un [Crypto] seule.
class Crypto {
 /// Identifiant CoinGecko (ex: "bitcoin"). Absent côté Binance.
  final String id;

  final String name;

  /// Toujours normalisé en minuscules pour rester cohérent entre
  /// CoinGecko ("btc") et Binance ("BTC").
  final String symbol;

  final double currentPrice;

  /// Absent des tickers Binance — nullable pour cette raison.
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

  /// Construit un [Crypto] à partir d'une entrée de la réponse
  /// `/coins/markets` de CoinGecko.
  ///
  /// Lève une [FormatException] si un champ requis (id, name, symbol,
  /// current_price) est manquant. Si `last_updated` est absent ou mal
  /// formaté, la date courante est utilisée en fallback.


  factory Crypto.fromCoinGeckoJson(Map<String, dynamic> json) { 
    if (json['id'] == null || json['name'] == null || 
      json['symbol'] == null || json['current_price'] == null) {
      throw FormatException('Champ requis manquant dans le JSON CoinGecko: ${json['id'] ?? 'id inconnu'}');
    }
    return Crypto(
      id: json['id'],
      name: json['name'],
      symbol: json['symbol'].toLowerCase(),
      currentPrice: (json['current_price'] as num).toDouble(),
      imageUrl: json['image'],
      priceChangePercentage24h:
          (json['price_change_percentage_24h'] as num?)?.toDouble(),
      high24h: (json['high_24h'] as num?)?.toDouble(),
      low24h: (json['low_24h'] as num?)?.toDouble(),
      marketCap: (json['market_cap'] as num?)?.toDouble(),
      marketCapRank: (json['market_cap_rank'] as num?)?.toInt(),
      lastUpdated: json['last_updated'] != null
    ? DateTime.tryParse(json['last_updated']) ?? DateTime.now()
    : DateTime.now(),
      volume24h: (json['total_volume'] as num?)?.toDouble(),
    );
  }

  /// Met à jour ce [Crypto] à partir d'un message du flux WebSocket
  /// Binance `<symbol>@ticker`.
  ///
  /// Ne crée jamais un nouvel objet depuis zéro : Binance ne fournit ni
  /// id, ni name, ni image, ni market cap. Un champ manquant ou corrompu
  /// dans le ticker conserve simplement l'ancienne valeur plutôt que de
  /// faire échouer la mise à jour.

  Crypto updateFromBinanceTicker(Map<String, dynamic> json) {
  return copyWith(
    currentPrice: json['c'] != null 
        ? double.tryParse(json['c']) 
        : null,
    priceChangePercentage24h: json['P'] != null 
        ? double.tryParse(json['P']) 
        : null,
    high24h: json['h'] != null 
        ? double.tryParse(json['h']) 
        : null,
    low24h: json['l'] != null 
        ? double.tryParse(json['l']) 
        : null,
    volume24h: json['q'] != null 
        ? double.tryParse(json['q']) 
        : null,
    lastUpdated: json['E'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(json['E']) 
        : null,
  );
}
    
}