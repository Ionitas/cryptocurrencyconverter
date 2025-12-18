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
}
