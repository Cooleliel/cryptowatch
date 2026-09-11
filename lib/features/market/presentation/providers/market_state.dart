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
  const MarketLoaded(this.cryptos, {this.query = ''});

  /// Liste brute renvoyée par l'API. La recherche ne la modifie jamais.
  final List<Crypto> cryptos;

  /// Texte saisi dans le champ de recherche.
  final String query;

  /// Cryptos affichées : toutes si [query] est vide, sinon nom ou symbole.
  List<Crypto> get visibleCryptos {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return cryptos;

    return cryptos
        .where(
          (crypto) =>
              crypto.name.toLowerCase().contains(needle) ||
              crypto.symbol.toLowerCase().contains(needle),
        )
        .toList();
  }

  MarketLoaded copyWith({List<Crypto>? cryptos, String? query}) {
    return MarketLoaded(
      cryptos ?? this.cryptos,
      query: query ?? this.query,
    );
  }
}