import 'package:flutter/foundation.dart';
import '../../domain/models/currency.dart';
import '../../domain/repositories/currency_repository.dart';
import '../datasources/crypto_api_datasource.dart';
import '../datasources/fiat_api_datasource.dart';
import '../datasources/local_cache_datasource.dart';

/// Implementation of CurrencyRepository
///
/// Client-side only data fetching:
/// 1. Local cache (return immediately, refresh in background if stale)
/// 2. Direct API calls in parallel (CoinCap/CoinGecko + ExchangeRate)
/// 3. Heavy JSON parsing offloaded to isolates via compute()
///
/// 24h change calculation:
/// - Crypto: Comes directly from CoinCap/CoinGecko APIs
/// - Fiat: Calculated by comparing current rates with historical rates (24h ago)
class CurrencyRepositoryImpl implements CurrencyRepository {
  final CryptoApiDataSource cryptoDataSource;
  final FiatApiDataSource fiatDataSource;
  final LocalCacheDataSource cacheDataSource;

  List<Currency> _currencies = [];
  bool _isBackgroundRefreshing = false;

  /// Callback for notifying UI of background updates
  VoidCallback? onCurrenciesUpdated;

  CurrencyRepositoryImpl({
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
          'Loaded ${_currencies.length} currencies from CACHE in ${cacheLoadTime}ms');

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

    // No cache or force refresh: fetch from APIs directly
    _debugLog('Fetching from direct APIs...');
    final fallbackResult = await _fetchFromDirectApis();
    final totalTime =
        DateTime.now().difference(overallStartTime).inMilliseconds;
    _debugLog('Total load time: ${totalTime}ms (from APIs)');
    return fallbackResult;
  }

  /// Fetches rates directly from external APIs using parallel requests
  /// JSON parsing is offloaded to isolates for performance
  Future<LoadResult> _fetchFromDirectApis() async {
    final startTime = DateTime.now();
    try {
      _debugLog(
          'Fetching from direct APIs (CoinCap/CoinGecko + ExchangeRate) in parallel...');
      final isPremiumUser = cacheDataSource.isPremium();

      // Save historical snapshot for 24h change calculation (if needed)
      if (cacheDataSource.shouldSaveHistoricalSnapshot()) {
        final currentCurrencies = cacheDataSource.getCachedCurrencies();
        if (currentCurrencies.isNotEmpty) {
          _debugLog('Saving historical snapshot for 24h change calculation...');
          await cacheDataSource.saveHistoricalRates(currentCurrencies);
        }
      }

      // Fetch fiat and crypto in parallel for maximum speed
      final results = await Future.wait([
        fiatDataSource.fetchFiatCurrencies(),
        cryptoDataSource.fetchCryptocurrencies(isPremium: isPremiumUser),
      ]);
      final fetchTime = DateTime.now().difference(startTime).inMilliseconds;

      final fiat = results[0];
      final crypto = results[1];

      // Apply 24h change calculation for fiat currencies using compute() isolate
      final fiatWithChange = await _applyFiat24hChangeIsolate(fiat);
      _currencies = [...fiatWithChange, ...crypto];

      if (_currencies.isNotEmpty) {
        // Save to cache (non-blocking)
        cacheDataSource.saveCurrencies(_currencies);
        final totalTime = DateTime.now().difference(startTime).inMilliseconds;
        _debugLog(
            'Fetched from DIRECT APIs: ${_currencies.length} currencies (${fiat.length} fiat, ${crypto.length} crypto) in ${totalTime}ms');
        return LoadResult(
          success: true,
          fromCache: false,
          message: 'Fetched fresh data',
          currencies: _currencies,
        );
      }

      _debugLog('Direct APIs returned no data after ${fetchTime}ms');
      return LoadResult(
        success: false,
        fromCache: false,
        message: 'No data received',
        currencies: [],
      );
    } catch (e) {
      _debugLog('Direct API error: $e - Attempting to load from cache');
      // On error, try to load from cache
      _currencies = cacheDataSource.getCachedCurrencies();
      if (_currencies.isNotEmpty) {
        _debugLog('Recovered ${_currencies.length} currencies from cache');
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
      if (cacheDataSource.shouldSaveHistoricalSnapshot() &&
          _currencies.isNotEmpty) {
        _debugLog('Saving historical snapshot for 24h change calculation...');
        await cacheDataSource.saveHistoricalRates(_currencies);
      }

      final isPremiumUser = cacheDataSource.isPremium();

      // Fetch both in parallel
      final results = await Future.wait([
        fiatDataSource.fetchFiatCurrencies(),
        cryptoDataSource.fetchCryptocurrencies(isPremium: isPremiumUser),
      ]);

      final fiatRates = results[0];
      final cryptoRates = results[1];

      if (fiatRates.isNotEmpty || cryptoRates.isNotEmpty) {
        // Apply 24h change calculation for fiat using isolate
        final fiatWithChange = await _applyFiat24hChangeIsolate(fiatRates);
        final newCurrencies = [...fiatWithChange, ...cryptoRates];

        if (newCurrencies.isNotEmpty) {
          _currencies = newCurrencies;
          await cacheDataSource.saveCurrencies(_currencies);

          final duration = DateTime.now().difference(startTime).inMilliseconds;
          _debugLog(
              'Background refresh complete: ${_currencies.length} currencies in ${duration}ms');

          // Notify listeners that currencies have been updated
          onCurrenciesUpdated?.call();
        }
      }
    } catch (e) {
      _debugLog('Background refresh error: $e');
    } finally {
      _isBackgroundRefreshing = false;
    }
  }

  /// Calculates 24h change for fiat currencies using a compute() isolate
  /// to avoid blocking the main thread with potentially heavy map operations
  Future<List<Currency>> _applyFiat24hChangeIsolate(
      List<Currency> fiatCurrencies) async {
    final historicalRates = cacheDataSource.getHistoricalRates();

    if (historicalRates == null || historicalRates.isEmpty) {
      _debugLog('No historical rates available for 24h change calculation');
      return fiatCurrencies;
    }

    // Offload to isolate via compute() for large lists
    if (fiatCurrencies.length > 20) {
      return compute(
        _computeFiat24hChange,
        _Fiat24hChangePayload(
          fiatCurrencies: fiatCurrencies,
          historicalRates: historicalRates,
        ),
      );
    }

    // For small lists, do it on the main thread
    return _applyFiat24hChange(fiatCurrencies, historicalRates);
  }

  /// Static top-level function for compute() isolate
  static List<Currency> _computeFiat24hChange(_Fiat24hChangePayload payload) {
    return _applyFiat24hChange(payload.fiatCurrencies, payload.historicalRates);
  }

  /// Pure function to calculate 24h change - works in any isolate
  static List<Currency> _applyFiat24hChange(
      List<Currency> fiatCurrencies, Map<String, double> historicalRates) {
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

/// Payload for passing data to compute() isolate
class _Fiat24hChangePayload {
  final List<Currency> fiatCurrencies;
  final Map<String, double> historicalRates;

  _Fiat24hChangePayload({
    required this.fiatCurrencies,
    required this.historicalRates,
  });
}
