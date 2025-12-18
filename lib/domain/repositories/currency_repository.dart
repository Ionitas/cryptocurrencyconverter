import '../models/currency.dart';

/// Result of loading currencies
class LoadResult {
  final bool success;
  final bool fromCache;
  final String message;
  final List<Currency> currencies;

  const LoadResult({
    required this.success,
    required this.fromCache,
    required this.message,
    required this.currencies,
  });
}

/// Abstract repository for currency operations
abstract class CurrencyRepository {
  /// Get all available currencies
  List<Currency> get allCurrencies;

  /// Load currencies from API or cache
  Future<LoadResult> loadCurrencies({bool forceRefresh = false});

  /// Convert amount from one currency to another
  double convert(double amount, Currency from, Currency to);

  /// Get the next update time for cached data
  String getNextUpdateTime();

  /// Get the last update time
  Future<DateTime?> getLastUpdateTime();

  /// Check if user has premium access
  Future<bool> get isPremium;

  /// Set premium status
  Future<void> setPremium(bool value);
}
