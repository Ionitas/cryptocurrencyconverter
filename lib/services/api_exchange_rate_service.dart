import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'exchange_rate_service.dart';
import '../models/exchange_rate.dart';

class _Config {
  // Fiat currency exchange rates API
  static const String fiatApiUrl = 'https://api.exchangerate-api.com/v4/latest/USD';

  // Cryptocurrency market data API
  static const String cryptoApiUrl = 'https://api.coingecko.com/api/v3/coins/markets';

  // Default base currency
  static const String baseCurrency = 'USD';

  // HTTP request timeout in seconds
  static const int requestTimeoutSeconds = 10;
}

class ApiExchangeRateService implements ExchangeRateService {
  @override
  Future<ExchangeRate> fetchRates() async {
    final fiatRates = await _fetchFiatRates();
    final cryptoRates = await _fetchCryptoRates();

    final allRates = <String, double>{_Config.baseCurrency: 1.0, ...fiatRates, ...cryptoRates};

    return ExchangeRate(baseCurrency: _Config.baseCurrency, rates: allRates, lastUpdated: DateTime.now());
  }

  Future<Map<String, double>> _fetchFiatRates() async {
    try {
      final response = await http
          .get(Uri.parse(_Config.fiatApiUrl))
          .timeout(Duration(seconds: _Config.requestTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        return rates.map((key, value) => MapEntry(key, (value as num).toDouble()));
      } else {
        debugPrint('Fiat API returned status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching fiat rates: $e');
    }

    return _getMockFiatRates();
  }

  Future<Map<String, double>> _fetchCryptoRates() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${_Config.cryptoApiUrl}?vs_currency=usd&order=market_cap_desc&per_page=100&page=1&sparkline=false',
            ),
          )
          .timeout(Duration(seconds: _Config.requestTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final rates = <String, double>{};

        for (final coin in data) {
          final symbol = (coin['symbol'] as String).toUpperCase();
          final price = (coin['current_price'] as num).toDouble();

          if (price > 0) {
            rates[symbol] = 1.0 / price;
          }
        }

        return rates;
      } else {
        debugPrint('Crypto API returned status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching crypto rates: $e');
    }

    return _getMockCryptoRates();
  }

  Map<String, double> _getMockFiatRates() {
    return {
      'EUR': 0.92,
      'GBP': 0.79,
      'JPY': 149.50,
      'CHF': 0.88,
      'CAD': 1.36,
      'AUD': 1.53,
      'CNY': 7.24,
      'RUB': 92.50,
      'INR': 83.12,
      'BRL': 4.97,
      'ZAR': 18.75,
      'MXN': 17.08,
      'SGD': 1.34,
      'HKD': 7.83,
      'NOK': 10.87,
      'SEK': 10.52,
      'DKK': 6.87,
      'NZD': 1.64,
      'KRW': 1308.50,
      'TRY': 32.15,
      'PLN': 3.98,
      'CZK': 22.35,
      'THB': 35.42,
      'MYR': 4.72,
      'IDR': 15678.00,
      'PHP': 56.18,
      'AED': 3.67,
      'SAR': 3.75,
      'ILS': 3.64,
    };
  }

  Map<String, double> _getMockCryptoRates() {
    return {
      'BTC': 0.000023,
      'ETH': 0.00030,
      'USDT': 1.0,
      'BNB': 0.0016,
      'SOL': 0.0095,
      'XRP': 1.85,
      'ADA': 2.22,
      'DOGE': 11.11,
      'AVAX': 0.028,
      'DOT': 0.14,
      'MATIC': 1.25,
      'LTC': 0.014,
      'LINK': 0.071,
      'UNI': 0.14,
      'ATOM': 0.11,
    };
  }
}
