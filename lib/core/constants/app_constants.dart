/// Application-wide constants
class AppConstants {
  AppConstants._();

  // API Endpoints
  static const String coinCapBaseUrl = 'https://api.coincap.io/v2';
  static const String coinGeckoBaseUrl = 'https://api.coingecko.com/api/v3';
  static const String exchangeRateBaseUrl =
      'https://api.exchangerate-api.com/v4/latest';

  // Cache Settings
  static const int cacheValidityHours = 12;

  // Currency Limits
  static const int freeCryptoLimit = 100;
  static const int premiumCryptoLimit = 250;

  // Default Display Currencies
  static const List<String> defaultDisplayCurrencies = [
    'USD',
    'EUR',
    'ETH',
    'GBP',
    'JPY',
    'USDT'
  ];
}
