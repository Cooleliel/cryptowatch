//**  Construit un objet BinanceTicker à partir d'un objet décodé (généralement un Map<String, dynamic>).*/
class BinanceTicker {
  const BinanceTicker({required this.symbol, required this.raw});

  final String symbol;
  final Map<String, dynamic> raw;

  //**  Construit un objet BinanceTicker à partir d'un objet décodé (généralement un Map<String, dynamic>).*/
  static BinanceTicker? tryParse(Object? decoded) {
    if (decoded is! Map<String, dynamic>) return null;

    final Object? symbol =
        decoded['s']; //** Récupère le symbole du ticker à partir de la clé 's' dans le Map. */

    if (symbol is! String || symbol.isEmpty) return null;

    String cleaned = symbol.toLowerCase();

    if (cleaned.endsWith('usdt')) {
      cleaned = cleaned.substring(
        0,
        cleaned.length - 4,
      ); //** Supprime le suffixe 'usdt' du symbole pour obtenir le nom de la paire de trading. */
    }
    if (cleaned.isEmpty) return null;
    return BinanceTicker(symbol: cleaned, raw: decoded);
  }
}
