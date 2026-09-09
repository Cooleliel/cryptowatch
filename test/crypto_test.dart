import 'package:flutter_test/flutter_test.dart';
import 'package:cryptowatch/features/market/domain/crypto.dart';

void main() {
  group('Crypto.fromCoinGeckoJson', () {
    test('parse un JSON complet et valide', () {
      final json = {
        'id': 'bitcoin',
        'name': 'Bitcoin',
        'symbol': 'BTC',
        'current_price': 45230.12,
        'image': 'https://example.com/btc.png',
        'price_change_percentage_24h': 2.5,
        'high_24h': 45900.0,
        'low_24h': 44100.0,
        'market_cap': 890000000000,
        'market_cap_rank': 1,
        'last_updated': '2026-09-07T10:00:00.000Z',
        'total_volume': 25000000000,
      };

      final crypto = Crypto.fromCoinGeckoJson(json);

      expect(crypto.id, 'bitcoin');
      expect(crypto.symbol, 'btc'); // normalisé en lowercase
      expect(crypto.currentPrice, 45230.12);
    });

    test('lève une FormatException si "id" est manquant', () {
      final json = {'name': 'Bitcoin', 'symbol': 'BTC', 'current_price': 45230.0};
      expect(() => Crypto.fromCoinGeckoJson(json), throwsFormatException);
    });

    test('lève une FormatException si "current_price" est manquant', () {
      final json = {'id': 'bitcoin', 'name': 'Bitcoin', 'symbol': 'BTC'};
      expect(() => Crypto.fromCoinGeckoJson(json), throwsFormatException);
    });

    test('accepte current_price envoyé en int (nombre rond)', () {
      final json = {
        'id': 'bitcoin', 'name': 'Bitcoin', 'symbol': 'BTC',
        'current_price': 45000, // int, pas double
        'last_updated': '2026-09-07T10:00:00.000Z',
      };
      final crypto = Crypto.fromCoinGeckoJson(json);
      expect(crypto.currentPrice, 45000.0);
    });

    test('accepte market_cap_rank envoyé en double', () {
      final json = {
        'id': 'bitcoin', 'name': 'Bitcoin', 'symbol': 'BTC',
        'current_price': 45000.0, 'market_cap_rank': 1.0,
        'last_updated': '2026-09-07T10:00:00.000Z',
      };
      final crypto = Crypto.fromCoinGeckoJson(json);
      expect(crypto.marketCapRank, 1);
    });

    test('fallback sur DateTime.now() si last_updated est absent', () {
      final json = {'id': 'bitcoin', 'name': 'Bitcoin', 'symbol': 'BTC', 'current_price': 45000.0};
      final before = DateTime.now();
      final crypto = Crypto.fromCoinGeckoJson(json);
      expect(crypto.lastUpdated.isAfter(before.subtract(const Duration(seconds: 1))), true);
    });

    test('fallback sur DateTime.now() si last_updated est mal formaté', () {
      final json = {
        'id': 'bitcoin', 'name': 'Bitcoin', 'symbol': 'BTC',
        'current_price': 45000.0, 'last_updated': 'pas-une-date',
      };
      expect(() => Crypto.fromCoinGeckoJson(json), returnsNormally);
    });

    test('champs optionnels absents deviennent null sans planter', () {
      final json = {
        'id': 'bitcoin', 'name': 'Bitcoin', 'symbol': 'BTC',
        'current_price': 45000.0, 'last_updated': '2026-09-07T10:00:00.000Z',
      };
      final crypto = Crypto.fromCoinGeckoJson(json);
      expect(crypto.imageUrl, isNull);
      expect(crypto.marketCap, isNull);
      expect(crypto.volume24h, isNull);
    });
  });

  group('Crypto.updateFromBinanceTicker', () {
    late Crypto baseCrypto;

    setUp(() {
      baseCrypto = Crypto(
        id: 'bitcoin',
        name: 'Bitcoin',
        symbol: 'btc',
        currentPrice: 40000.0,
        lastUpdated: DateTime(2026, 1, 1),
      );
    });

    test('met à jour le prix depuis une string Binance', () {
      final ticker = {'c': '45230.12'};
      final updated = baseCrypto.updateFromBinanceTicker(ticker);
      expect(updated.currentPrice, 45230.12);
    });

    test('conserve id, name, symbol, imageUrl inchangés', () {
      final ticker = {'c': '45230.12', 'P': '2.5'};
      final updated = baseCrypto.updateFromBinanceTicker(ticker);
      expect(updated.id, baseCrypto.id);
      expect(updated.name, baseCrypto.name);
      expect(updated.symbol, baseCrypto.symbol);
    });

    test('garde l\'ancien prix si le champ Binance est corrompu', () {
      final ticker = {'c': 'valeur-invalide'};
      final updated = baseCrypto.updateFromBinanceTicker(ticker);
      expect(updated.currentPrice, baseCrypto.currentPrice); // inchangé
    });

    test('convertit correctement le timestamp E en DateTime', () {
      final ticker = {'E': 1725600000000};
      final updated = baseCrypto.updateFromBinanceTicker(ticker);
      expect(updated.lastUpdated, DateTime.fromMillisecondsSinceEpoch(1725600000000));
    });

    test('ne modifie pas l\'objet original (immutabilité)', () {
      final ticker = {'c': '45230.12'};
      baseCrypto.updateFromBinanceTicker(ticker);
      expect(baseCrypto.currentPrice, 40000.0); // toujours l'ancienne valeur
    });
  });

  group('Crypto.copyWith', () {
    test('ne modifie que le champ demandé', () {
      final original = Crypto(
        id: 'bitcoin', name: 'Bitcoin', symbol: 'btc',
        currentPrice: 40000.0, lastUpdated: DateTime(2026, 1, 1),
      );
      final updated = original.copyWith(currentPrice: 41000.0);

      expect(updated.currentPrice, 41000.0);
      expect(updated.name, original.name);
      expect(updated.symbol, original.symbol);
      expect(original.currentPrice, 40000.0); // original intact
    });
  });
}