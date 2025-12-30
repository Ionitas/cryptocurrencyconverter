import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/currency.dart';

/// Local data source for caching currency data
class LocalCacheDataSource {
  final SharedPreferences _prefs;

  static const String _currenciesKey = 'cached_currencies';
  static const String _lastFetchKey = 'last_fetch_time';
  static const String _isPremiumKey = 'is_premium';
  static const String _historicalRatesKey = 'historical_rates';
  static const String _historicalRatesTimestampKey =
      'historical_rates_timestamp';

  LocalCacheDataSource(this._prefs);

  /// Check if cache is still valid (within 12 hours)
  bool isCacheValid() {
    final lastFetch = _prefs.getString(_lastFetchKey);
    if (lastFetch == null) return false;

    final lastFetchTime = DateTime.parse(lastFetch);
    final now = DateTime.now();
    return now.difference(lastFetchTime).inHours <
        AppConstants.cacheValidityHours;
  }

  /// Get cached currencies
  List<Currency> getCachedCurrencies() {
    final jsonString = _prefs.getString(_currenciesKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((j) => Currency.fromJson(j)).toList();
    } catch (e) {
      print('Error reading cache: $e');
      return [];
    }
  }

  /// Save currencies to cache
  Future<void> saveCurrencies(List<Currency> currencies) async {
    final jsonList = currencies.map((c) => c.toJson()).toList();
    await _prefs.setString(_currenciesKey, json.encode(jsonList));
    await _prefs.setString(_lastFetchKey, DateTime.now().toIso8601String());
  }

  /// Clear cache
  Future<void> clearCache() async {
    await _prefs.remove(_currenciesKey);
    await _prefs.remove(_lastFetchKey);
  }

  /// Get last fetch time
  DateTime? getLastFetchTime() {
    final lastFetch = _prefs.getString(_lastFetchKey);
    if (lastFetch == null) return null;
    return DateTime.parse(lastFetch);
  }

  /// Get next scheduled update time
  String getNextFetchTime() {
    final lastFetch = getLastFetchTime();
    if (lastFetch == null) return 'Not available';

    final nextFetch = lastFetch.add(
      const Duration(hours: AppConstants.cacheValidityHours),
    );
    final now = DateTime.now();

    if (nextFetch.isBefore(now)) return 'Ready to update';

    final diff = nextFetch.difference(now);
    if (diff.inHours > 0) {
      return 'in ${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    return 'in ${diff.inMinutes}m';
  }

  /// Check if user has premium access
  bool isPremium() {
    return _prefs.getBool(_isPremiumKey) ?? false;
  }

  /// Set premium status
  Future<void> setPremium(bool value) async {
    await _prefs.setBool(_isPremiumKey, value);
  }

  // =============================================
  // HISTORICAL RATES FOR 24H CHANGE CALCULATION
  // =============================================

  /// Save current rates as historical snapshot for 24h change calculation
  /// Only saves fiat rates as crypto already has 24h change from API
  Future<void> saveHistoricalRates(List<Currency> currencies) async {
    final fiatRates = currencies.where((c) => !c.isCrypto).toList();
    if (fiatRates.isEmpty) return;

    final Map<String, double> ratesMap = {};
    for (final currency in fiatRates) {
      ratesMap[currency.code] = currency.priceUsd;
    }

    await _prefs.setString(_historicalRatesKey, json.encode(ratesMap));
    await _prefs.setString(
      _historicalRatesTimestampKey,
      DateTime.now().toIso8601String(),
    );
  }

  /// Get historical rates if they are approximately 24 hours old (18-30 hours)
  /// Returns null if no historical data or data is too old/new
  Map<String, double>? getHistoricalRates() {
    final jsonString = _prefs.getString(_historicalRatesKey);
    final timestamp = _prefs.getString(_historicalRatesTimestampKey);

    if (jsonString == null || timestamp == null) return null;

    try {
      final savedTime = DateTime.parse(timestamp);
      final age = DateTime.now().difference(savedTime);

      // Historical data should be between 18-30 hours old for accurate 24h change
      // If it's older than 30 hours, we should refresh it
      // If it's newer than 18 hours, it's too recent to calculate 24h change
      if (age.inHours >= 18 && age.inHours <= 30) {
        final Map<String, dynamic> decoded = json.decode(jsonString);
        return decoded
            .map((key, value) => MapEntry(key, (value as num).toDouble()));
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get raw historical rates regardless of age (for updating/migrating)
  Map<String, double>? getRawHistoricalRates() {
    final jsonString = _prefs.getString(_historicalRatesKey);
    if (jsonString == null) return null;

    try {
      final Map<String, dynamic> decoded = json.decode(jsonString);
      return decoded
          .map((key, value) => MapEntry(key, (value as num).toDouble()));
    } catch (e) {
      return null;
    }
  }

  /// Get the timestamp of historical rates
  DateTime? getHistoricalRatesTimestamp() {
    final timestamp = _prefs.getString(_historicalRatesTimestampKey);
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }

  /// Check if we should save new historical snapshot
  /// Returns true if no historical data exists or it's older than 20 hours
  bool shouldSaveHistoricalSnapshot() {
    final timestamp = getHistoricalRatesTimestamp();
    if (timestamp == null) return true;

    final age = DateTime.now().difference(timestamp);
    return age.inHours >= 20;
  }
}
