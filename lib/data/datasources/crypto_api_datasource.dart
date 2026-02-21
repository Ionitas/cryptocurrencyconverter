import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../domain/models/currency.dart';

/// Data source for fetching cryptocurrency data from external APIs
/// Uses compute() isolates for heavy JSON parsing to keep the UI responsive
class CryptoApiDataSource {
  /// Fetches cryptocurrencies from CoinCap or CoinGecko APIs
  /// Falls back to hardcoded data if both APIs fail
  Future<List<Currency>> fetchCryptocurrencies({bool isPremium = false}) async {
    final limit = isPremium
        ? AppConstants.premiumCryptoLimit
        : AppConstants.freeCryptoLimit;

    // Try CoinCap first
    final coinCapResult = await _fetchFromCoinCap(limit);
    if (coinCapResult.isNotEmpty) return coinCapResult;

    // Fallback to CoinGecko
    final coinGeckoResult = await _fetchFromCoinGecko(limit);
    if (coinGeckoResult.isNotEmpty) return coinGeckoResult;

    // Return fallback data if both APIs fail
    return _getFallbackCryptos();
  }

  Future<List<Currency>> _fetchFromCoinCap(int limit) async {
    try {
      final response = await http
          .get(Uri.parse('${AppConstants.coinCapBaseUrl}/assets?limit=$limit'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Offload JSON decoding + parsing to isolate for large responses
        return compute(_parseCoinCapResponse, response.body);
      }
    } catch (e) {
      debugPrint('CoinCap API error: $e');
    }
    return [];
  }

  /// Static top-level function for compute() isolate - CoinCap parsing
  static List<Currency> _parseCoinCapResponse(String responseBody) {
    try {
      final data = json.decode(responseBody);
      final List<dynamic> assets = data['data'] ?? [];
      if (assets.isNotEmpty) {
        return assets.map((asset) => Currency.fromCoinCap(asset)).toList();
      }
    } catch (e) {
      // Parsing failed in isolate
    }
    return [];
  }

  Future<List<Currency>> _fetchFromCoinGecko(int limit) async {
    try {
      final url = '${AppConstants.coinGeckoBaseUrl}/coins/markets'
          '?vs_currency=usd&order=market_cap_desc&per_page=$limit'
          '&page=1&sparkline=false&price_change_percentage=24h';

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Offload JSON decoding + parsing to isolate
        return compute(_parseCoinGeckoResponse, response.body);
      }
    } catch (e) {
      debugPrint('CoinGecko API error: $e');
    }
    return [];
  }

  /// Static top-level function for compute() isolate - CoinGecko parsing
  static List<Currency> _parseCoinGeckoResponse(String responseBody) {
    try {
      final List<dynamic> coins = json.decode(responseBody);
      return coins
          .map((coin) => Currency(
                id: coin['id'] ?? '',
                code: (coin['symbol'] ?? '').toString().toUpperCase(),
                symbol: (coin['symbol'] ?? '').toString().toUpperCase(),
                name: coin['name'] ?? '',
                priceUsd: (coin['current_price'] ?? 0).toDouble(),
                changePercent24h:
                    (coin['price_change_percentage_24h'] ?? 0).toDouble(),
                isCrypto: true,
                lastUpdated: DateTime.now(),
              ))
          .toList();
    } catch (e) {
      // Parsing failed in isolate
    }
    return [];
  }

  List<Currency> _getFallbackCryptos() {
    const cryptoData = [
      {'symbol': 'BTC', 'name': 'Bitcoin', 'price': 42000.0},
      {'symbol': 'ETH', 'name': 'Ethereum', 'price': 2200.0},
      {'symbol': 'USDT', 'name': 'Tether', 'price': 1.0},
      {'symbol': 'BNB', 'name': 'BNB', 'price': 300.0},
      {'symbol': 'SOL', 'name': 'Solana', 'price': 100.0},
      {'symbol': 'XRP', 'name': 'XRP', 'price': 0.6},
      {'symbol': 'USDC', 'name': 'USD Coin', 'price': 1.0},
      {'symbol': 'ADA', 'name': 'Cardano', 'price': 0.5},
      {'symbol': 'DOGE', 'name': 'Dogecoin', 'price': 0.08},
      {'symbol': 'TRX', 'name': 'TRON', 'price': 0.1},
      {'symbol': 'TON', 'name': 'Toncoin', 'price': 2.5},
      {'symbol': 'LINK', 'name': 'Chainlink', 'price': 15.0},
      {'symbol': 'AVAX', 'name': 'Avalanche', 'price': 35.0},
      {'symbol': 'SHIB', 'name': 'Shiba Inu', 'price': 0.000009},
      {'symbol': 'DOT', 'name': 'Polkadot', 'price': 7.0},
      {'symbol': 'BCH', 'name': 'Bitcoin Cash', 'price': 250.0},
      {'symbol': 'UNI', 'name': 'Uniswap', 'price': 6.0},
      {'symbol': 'LTC', 'name': 'Litecoin', 'price': 70.0},
      {'symbol': 'NEAR', 'name': 'NEAR Protocol', 'price': 3.5},
      {'symbol': 'MATIC', 'name': 'Polygon', 'price': 0.8},
      {'symbol': 'DAI', 'name': 'Dai', 'price': 1.0},
      {'symbol': 'LEO', 'name': 'UNUS SED LEO', 'price': 6.0},
      {'symbol': 'ICP', 'name': 'Internet Computer', 'price': 12.0},
      {'symbol': 'ETC', 'name': 'Ethereum Classic', 'price': 20.0},
      {'symbol': 'APT', 'name': 'Aptos', 'price': 9.0},
      {'symbol': 'STX', 'name': 'Stacks', 'price': 1.5},
      {'symbol': 'XLM', 'name': 'Stellar', 'price': 0.12},
      {'symbol': 'ATOM', 'name': 'Cosmos', 'price': 10.0},
      {'symbol': 'OKB', 'name': 'OKB', 'price': 55.0},
      {'symbol': 'FIL', 'name': 'Filecoin', 'price': 5.0},
      {'symbol': 'HBAR', 'name': 'Hedera', 'price': 0.07},
      {'symbol': 'ARB', 'name': 'Arbitrum', 'price': 1.2},
      {'symbol': 'VET', 'name': 'VeChain', 'price': 0.03},
      {'symbol': 'INJ', 'name': 'Injective', 'price': 35.0},
      {'symbol': 'OP', 'name': 'Optimism', 'price': 2.0},
      {'symbol': 'MKR', 'name': 'Maker', 'price': 1500.0},
      {'symbol': 'GRT', 'name': 'The Graph', 'price': 0.15},
      {'symbol': 'ALGO', 'name': 'Algorand', 'price': 0.18},
      {'symbol': 'AAVE', 'name': 'Aave', 'price': 100.0},
      {'symbol': 'XTZ', 'name': 'Tezos', 'price': 0.9},
      {'symbol': 'SAND', 'name': 'The Sandbox', 'price': 0.5},
      {'symbol': 'AXS', 'name': 'Axie Infinity', 'price': 8.0},
      {'symbol': 'MANA', 'name': 'Decentraland', 'price': 0.5},
      {'symbol': 'FTM', 'name': 'Fantom', 'price': 0.4},
      {'symbol': 'XMR', 'name': 'Monero', 'price': 160.0},
      {'symbol': 'PEPE', 'name': 'Pepe', 'price': 0.000001},
      {'symbol': 'SUI', 'name': 'Sui', 'price': 1.5},
      {'symbol': 'SEI', 'name': 'Sei', 'price': 0.5},
      {'symbol': 'WIF', 'name': 'dogwifhat', 'price': 2.0},
      {'symbol': 'BONK', 'name': 'Bonk', 'price': 0.00001},
    ];

    return cryptoData
        .map((c) => Currency(
              id: (c['symbol'] as String).toLowerCase(),
              code: c['symbol'] as String,
              symbol: c['symbol'] as String,
              name: c['name'] as String,
              priceUsd: c['price'] as double,
              changePercent24h: 0.0,
              isCrypto: true,
              lastUpdated: DateTime.now(),
            ))
        .toList();
  }
}
