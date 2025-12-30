import 'package:flutter/foundation.dart';
import '../../core/config/supabase_config.dart';
import '../../domain/models/currency.dart';
import '../../domain/repositories/currency_repository.dart';
import '../datasources/crypto_api_datasource.dart';
import '../datasources/fiat_api_datasource.dart';
import '../datasources/local_cache_datasource.dart';
import '../datasources/supabase_datasource.dart';

/// Implementation of CurrencyRepository
///
/// Data fetching priority:
/// 1. Local cache (return immediately, refresh in background if stale)
/// 2. Supabase backend (centralized, updated 3-5x/day)
/// 3. Direct API calls (CoinCap → CoinGecko → fallback)
///
/// 24h change calculation:
/// - Crypto: Comes directly from CoinCap/CoinGecko APIs
/// - Fiat: Calculated by comparing current rates with historical rates (24h ago)
class CurrencyRepositoryImpl implements CurrencyRepository {
  final SupabaseDataSource? supabaseDataSource;
  final CryptoApiDataSource cryptoDataSource;
  final FiatApiDataSource fiatDataSource;
  final LocalCacheDataSource cacheDataSource;

  List<Currency> _currencies = [];
  bool _isBackgroundRefreshing = false;

  /// Callback for notifying UI of background updates
  VoidCallback? onCurrenciesUpdated;

  CurrencyRepositoryImpl({
    this.supabaseDataSource,
    required this.cryptoDataSource,
    required this.fiatDataSource,
    required this.cacheDataSource,
  });

  @override
  List<Currency> get allCurrencies => _currencies;

  /// Debug logging helper - only logs in debug mode
  void _debugLog(String message) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      debugPrint('[CurrencyRepo $timestamp] $message');
    }
  }

  @override
  Future<LoadResult> loadCurrencies({bool forceRefresh = false}) async {
    final overallStartTime = DateTime.now();
    _debugLog('=== loadCurrencies started (forceRefresh: $forceRefresh) ===');

    // Log cache status
    final lastCacheFetch = cacheDataSource.getLastFetchTime();
    if (lastCacheFetch != null) {
      final cacheAge = DateTime.now().difference(lastCacheFetch);
      _debugLog(
          'Cache last fetched: ${lastCacheFetch.toIso8601String()} (${cacheAge.inMinutes} minutes ago)');
      _debugLog('Cache valid: ${cacheDataSource.isCacheValid()}');
    } else {
      _debugLog('No cache data available');
    }

    // CACHE-FIRST STRATEGY:
    // 1. Return cached data immediately if available
    // 2. Trigger background refresh if cache is stale
    // 3. Only wait for network if no cache exists or force refresh

    final cachedCurrencies = cacheDataSource.getCachedCurrencies();
    final hasCachedData = cachedCurrencies.isNotEmpty;
    final cacheIsValid = cacheDataSource.isCacheValid();

    // If we have cached data and not forcing refresh, return it immediately
    if (!forceRefresh && hasCachedData) {
      _currencies = cachedCurrencies;
      final cacheLoadTime =
          DateTime.now().difference(overallStartTime).inMilliseconds;
      _debugLog(
          '✓ Loaded ${_currencies.length} currencies from CACHE in ${cacheLoadTime}ms');

      // If cache is stale, trigger background refresh
      if (!cacheIsValid && !_isBackgroundRefreshing) {
        _debugLog('Cache is stale, triggering background refresh...');
        _backgroundRefresh();
      }

      return LoadResult(
        success: true,
        fromCache: true,
        message: cacheIsValid
            ? 'Loaded from cache'
            : 'Loaded from cache (updating in background)',
        currencies: _currencies,
      );
    }

    // Try Supabase first (centralized backend)
    if (supabaseDataSource != null && SupabaseConfig.isConfigured) {
      try {
        _debugLog('Attempting to fetch from Supabase...');
        final supabaseResult = await _fetchFromSupabase();
        if (supabaseResult != null) {
          final totalTime =
              DateTime.now().difference(overallStartTime).inMilliseconds;
          _debugLog('✓ Total load time: ${totalTime}ms (from Supabase)');
          return supabaseResult;
        }
      } catch (e) {
        _debugLog('✗ Supabase fetch failed: $e');
        // Continue to fallback APIs
      }
    } else {
      _debugLog('Supabase not configured or datasource is null');
    }

    // Fallback to direct API calls
    _debugLog('⚠ Falling back to direct API calls...');
    final fallbackResult = await _fetchFromDirectApis();
    final totalTime =
        DateTime.now().difference(overallStartTime).inMilliseconds;
    _debugLog('✓ Total load time: ${totalTime}ms (from fallback APIs)');
    return fallbackResult;
  }

  /// Fetches rates from Supabase backend
  Future<LoadResult?> _fetchFromSupabase() async {
    if (supabaseDataSource == null) return null;

    try {
      final startTime = DateTime.now();
      _debugLog('Fetching rates from Supabase...');
      final isPremiumUser = cacheDataSource.isPremium();

      // Fetch all rates from Supabase
      final allRates = await supabaseDataSource!.fetchAllRates();
      final fetchTime = DateTime.now().difference(startTime).inMilliseconds;

      // Get last update time from Supabase for logging
      final supabaseLastUpdate = await supabaseDataSource!.getLastUpdateTime();
      if (supabaseLastUpdate != null) {
        final updateAge = DateTime.now().difference(supabaseLastUpdate);
        _debugLog(
            'Supabase data last updated: ${supabaseLastUpdate.toIso8601String()} (${updateAge.inMinutes} minutes ago)');
      }

      if (allRates.isEmpty) {
        _debugLog('✗ Supabase returned empty rates after ${fetchTime}ms');
        return null;
      }

      // Save historical snapshot for 24h change calculation (if needed)
      if (cacheDataSource.shouldSaveHistoricalSnapshot()) {
        final currentCurrencies = cacheDataSource.getCachedCurrencies();
        if (currentCurrencies.isNotEmpty) {
          _debugLog('Saving historical snapshot for 24h change calculation...');
          await cacheDataSource.saveHistoricalRates(currentCurrencies);
        }
      }

      // Apply premium limit for crypto
      final cryptoLimit = isPremiumUser ? 250 : 100;
      final cryptoRates =
          allRates.where((c) => c.isCrypto).take(cryptoLimit).toList();
      final fiatRates = allRates.where((c) => !c.isCrypto).toList();

      // Apply 24h change calculation for fiat currencies
      final fiatWithChange = _applyFiat24hChange(fiatRates);
      _currencies = [...fiatWithChange, ...cryptoRates];

      if (_currencies.isNotEmpty) {
        await cacheDataSource.saveCurrencies(_currencies);
        final totalTime = DateTime.now().difference(startTime).inMilliseconds;
        _debugLog(
            '✓ Fetched from SUPABASE: ${_currencies.length} currencies (${fiatRates.length} fiat, ${cryptoRates.length} crypto) in ${totalTime}ms');
        _debugLog('  - Network fetch: ${fetchTime}ms');
        _debugLog(
            '  - Premium user: $isPremiumUser, crypto limit: $cryptoLimit');
        return LoadResult(
          success: true,
          fromCache: false,
          message: 'Fetched from Supabase',
          currencies: _currencies,
        );
      }

      return null;
    } catch (e) {
      _debugLog('✗ Supabase error: $e');
      return null;
    }
  }

  /// Fallback: Fetches rates directly from external APIs
  Future<LoadResult> _fetchFromDirectApis() async {
    final startTime = DateTime.now();
    try {
      _debugLog(
          '⚠ Falling back to direct API calls (CoinCap/CoinGecko/ExchangeRate)...');
      final isPremiumUser = cacheDataSource.isPremium();

      // Save historical snapshot for 24h change calculation (if needed)
      if (cacheDataSource.shouldSaveHistoricalSnapshot()) {
        final currentCurrencies = cacheDataSource.getCachedCurrencies();
        if (currentCurrencies.isNotEmpty) {
          _debugLog('Saving historical snapshot for 24h change calculation...');
          await cacheDataSource.saveHistoricalRates(currentCurrencies);
        }
      }

      final results = await Future.wait([
        fiatDataSource.fetchFiatCurrencies(),
        cryptoDataSource.fetchCryptocurrencies(isPremium: isPremiumUser),
      ]);
      final fetchTime = DateTime.now().difference(startTime).inMilliseconds;

      final fiat = results[0];
      final crypto = results[1];

      // Apply 24h change calculation for fiat currencies
      final fiatWithChange = _applyFiat24hChange(fiat);
      _currencies = [...fiatWithChange, ...crypto];

      if (_currencies.isNotEmpty) {
        await cacheDataSource.saveCurrencies(_currencies);
        final totalTime = DateTime.now().difference(startTime).inMilliseconds;
        _debugLog(
            '✓ Fetched from DIRECT APIs: ${_currencies.length} currencies (${fiat.length} fiat, ${crypto.length} crypto) in ${totalTime}ms');
        return LoadResult(
          success: true,
          fromCache: false,
          message: 'Fetched from direct APIs',
          currencies: _currencies,
        );
      }

      _debugLog('✗ Direct APIs returned no data after ${fetchTime}ms');
      return LoadResult(
        success: false,
        fromCache: false,
        message: 'No data received',
        currencies: [],
      );
    } catch (e) {
      _debugLog('✗ Direct API error: $e - Attempting to load from cache');
      // On error, try to load from cache
      _currencies = cacheDataSource.getCachedCurrencies();
      if (_currencies.isNotEmpty) {
        _debugLog('✓ Recovered ${_currencies.length} currencies from cache');
      }
      return LoadResult(
        success: _currencies.isNotEmpty,
        fromCache: true,
        message: 'API error, loaded from cache',
        currencies: _currencies,
      );
    }
  }

  @override
  double convert(double amount, Currency from, Currency to) {
    if (from.priceUsd == 0 || to.priceUsd == 0) return 0;
    final amountInUsd = amount * from.priceUsd;
    return amountInUsd / to.priceUsd;
  }

  @override
  String getNextUpdateTime() {
    return cacheDataSource.getNextFetchTime();
  }

  @override
  Future<DateTime?> getLastUpdateTime() async {
    return cacheDataSource.getLastFetchTime();
  }

  @override
  Future<bool> get isPremium async => cacheDataSource.isPremium();

  @override
  Future<void> setPremium(bool value) async {
    await cacheDataSource.setPremium(value);
    await cacheDataSource.clearCache();
  }

  // =============================================
  // BACKGROUND REFRESH & 24H CHANGE CALCULATION
  // =============================================

  /// Performs a background refresh of currency data
  /// Updates _currencies and notifies listeners when complete
  Future<void> _backgroundRefresh() async {
    if (_isBackgroundRefreshing) {
      _debugLog('Background refresh already in progress, skipping...');
      return;
    }

    _isBackgroundRefreshing = true;
    _debugLog('Starting background refresh...');
    final startTime = DateTime.now();

    try {
      // Before fetching new data, save current rates as historical snapshot
      // This is used for calculating 24h change for fiat currencies
      if (cacheDataSource.shouldSaveHistoricalSnapshot() &&
          _currencies.isNotEmpty) {
        _debugLog('Saving historical snapshot for 24h change calculation...');
        await cacheDataSource.saveHistoricalRates(_currencies);
      }

      List<Currency>? newCurrencies;

      // Try Supabase first
      if (supabaseDataSource != null && SupabaseConfig.isConfigured) {
        try {
          final isPremiumUser = cacheDataSource.isPremium();
          final allRates = await supabaseDataSource!.fetchAllRates();

          if (allRates.isNotEmpty) {
            final cryptoLimit = isPremiumUser ? 250 : 100;
            final cryptoRates =
                allRates.where((c) => c.isCrypto).take(cryptoLimit).toList();
            final fiatRates = allRates.where((c) => !c.isCrypto).toList();

            // Apply 24h change calculation for fiat
            final fiatWithChange = _applyFiat24hChange(fiatRates);
            newCurrencies = [...fiatWithChange, ...cryptoRates];
            _debugLog(
                '✓ Background: Fetched ${newCurrencies.length} from Supabase');
          }
        } catch (e) {
          _debugLog('✗ Background Supabase error: $e');
        }
      }

      // Fallback to direct APIs if Supabase failed
      if (newCurrencies == null || newCurrencies.isEmpty) {
        try {
          final isPremiumUser = cacheDataSource.isPremium();
          final results = await Future.wait([
            fiatDataSource.fetchFiatCurrencies(),
            cryptoDataSource.fetchCryptocurrencies(isPremium: isPremiumUser),
          ]);

          final fiatRates = results[0];
          final cryptoRates = results[1];

          // Apply 24h change calculation for fiat
          final fiatWithChange = _applyFiat24hChange(fiatRates);
          newCurrencies = [...fiatWithChange, ...cryptoRates];
          _debugLog(
              '✓ Background: Fetched ${newCurrencies.length} from direct APIs');
        } catch (e) {
          _debugLog('✗ Background direct API error: $e');
        }
      }

      // Update currencies if we got new data
      if (newCurrencies != null && newCurrencies.isNotEmpty) {
        _currencies = newCurrencies;
        await cacheDataSource.saveCurrencies(_currencies);

        final duration = DateTime.now().difference(startTime).inMilliseconds;
        _debugLog(
            '✓ Background refresh complete: ${_currencies.length} currencies in ${duration}ms');

        // Notify listeners that currencies have been updated
        onCurrenciesUpdated?.call();
      }
    } catch (e) {
      _debugLog('✗ Background refresh error: $e');
    } finally {
      _isBackgroundRefreshing = false;
    }
  }

  /// Calculates and applies 24h change percentage for fiat currencies
  /// by comparing current rates with historical rates from cache
  List<Currency> _applyFiat24hChange(List<Currency> fiatCurrencies) {
    final historicalRates = cacheDataSource.getHistoricalRates();

    if (historicalRates == null || historicalRates.isEmpty) {
      _debugLog('No historical rates available for 24h change calculation');
      return fiatCurrencies;
    }

    _debugLog(
        'Calculating 24h change for ${fiatCurrencies.length} fiat currencies...');

    return fiatCurrencies.map((currency) {
      final historicalRate = historicalRates[currency.code];
      if (historicalRate == null || historicalRate == 0) {
        return currency;
      }

      // Calculate percentage change: ((new - old) / old) * 100
      final change =
          ((currency.priceUsd - historicalRate) / historicalRate) * 100;

      return currency.copyWith(changePercent24h: change);
    }).toList();
  }

  /// Manually trigger a refresh (useful for pull-to-refresh)
  Future<LoadResult> refreshCurrencies() async {
    return loadCurrencies(forceRefresh: true);
  }
}
