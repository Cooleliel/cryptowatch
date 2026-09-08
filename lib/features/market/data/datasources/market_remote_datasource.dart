import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:cryptowatch/features/market/domain/crypto.dart';

class MarketRemoteDataSource {
	static const _topCryptosUrl =
			'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=50&page=1';

	Future<List<Crypto>> fetchTopCryptos() async {
		final response = await http.get(Uri.parse(_topCryptosUrl));

		if (response.statusCode != 200) {
			throw Exception('Failed to fetch top cryptocurrencies');
		}

		final decodedJson = jsonDecode(response.body);
		if (decodedJson is! List) {
			throw FormatException('Expected a list of cryptocurrencies');
		}

		return decodedJson
				.map((item) => Crypto.fromCoinGeckoJson(item as Map<String, dynamic>))
				.toList();
	}
}
