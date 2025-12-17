import 'exchange_rate_service.dart';
import '../models/exchange_rate.dart';

class MockExchangeRateService implements ExchangeRateService {
  @override
  Future<ExchangeRate> fetchRates() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return ExchangeRate(
      baseCurrency: 'USD',
      rates: {
        'USD': 1.0,
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
      },
      lastUpdated: DateTime.now(),
    );
  }
}
