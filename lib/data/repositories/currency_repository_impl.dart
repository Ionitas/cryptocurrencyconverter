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
/// 1. Local cache (if valid, < 12 hours old)
/// 2. Supabase backend (centralized, updated 3-5x/day)
/// 3. Direct API calls (CoinCap → CoinGecko → fallback)
class CurrencyRepositoryImpl implements CurrencyRepository {
  final SupabaseDataSource? supabaseDataSource;
  final CryptoApiDataSource cryptoDataSource;
  final FiatApiDataSource fiatDataSource;
  final LocalCacheDataSource cacheDataSource;

  List<Currency> _currencies = [];

  CurrencyRepositoryImpl({
    this.supabaseDataSource,
    required this.cryptoDataSource,
    required this.fiatDataSource,
    required this.cacheDataSource,
  });

  @override
  List<Currency> get allCurrencies => _currencies;

  @override
  Future<LoadResult> loadCurrencies({bool forceRefresh = false}) async {
    // Try to use local cache first (fastest)
    if (!forceRefresh && cacheDataSource.isCacheValid()) {
      _currencies = cacheDataSource.getCachedCurrencies();
      if (_currencies.isNotEmpty) {
        return LoadResult(
          success: true,
          fromCache: true,
          message: 'Loaded from cache',
          currencies: _currencies,
        );
      }
    }

    // Try Supabase first (centralized backend)
    if (supabaseDataSource != null && SupabaseConfig.isConfigured) {
      try {
        final supabaseResult = await _fetchFromSupabase();
        if (supabaseResult != null) {
          return supabaseResult;
        }
      } catch (e) {
        print('Supabase fetch failed: $e');
        // Continue to fallback APIs
      }
    }

    // Fallback to direct API calls
    return _fetchFromDirectApis();
  }

  /// Fetches rates from Supabase backend
  Future<LoadResult?> _fetchFromSupabase() async {
    if (supabaseDataSource == null) return null;

    try {
      print('Fetching rates from Supabase...');
      final isPremiumUser = cacheDataSource.isPremium();

      // Fetch all rates from Supabase
      final allRates = await supabaseDataSource!.fetchAllRates();

      if (allRates.isEmpty) {
        print('Supabase returned empty rates');
        return null;
      }

      // Apply premium limit for crypto
      final cryptoLimit = isPremiumUser ? 250 : 100;
      final cryptoRates =
          allRates.where((c) => c.isCrypto).take(cryptoLimit).toList();
      final fiatRates = allRates.where((c) => !c.isCrypto).toList();

      _currencies = [...fiatRates, ...cryptoRates];

      if (_currencies.isNotEmpty) {
        await cacheDataSource.saveCurrencies(_currencies);
        print('Fetched ${_currencies.length} rates from Supabase');
        return LoadResult(
          success: true,
          fromCache: false,
          message: 'Fetched from Supabase',
          currencies: _currencies,
        );
      }

      return null;
    } catch (e) {
      print('Supabase error: $e');
      return null;
    }
  }

  /// Fallback: Fetches rates directly from external APIs
  Future<LoadResult> _fetchFromDirectApis() async {
    try {
      print('Falling back to direct API calls...');
      final isPremiumUser = cacheDataSource.isPremium();

      final results = await Future.wait([
        fiatDataSource.fetchFiatCurrencies(),
        cryptoDataSource.fetchCryptocurrencies(isPremium: isPremiumUser),
      ]);

      final fiat = results[0];
      final crypto = results[1];

      _currencies = [...fiat, ...crypto];

      if (_currencies.isNotEmpty) {
        await cacheDataSource.saveCurrencies(_currencies);
        return LoadResult(
          success: true,
          fromCache: false,
          message: 'Fetched from direct APIs',
          currencies: _currencies,
        );
      }

      return LoadResult(
        success: false,
        fromCache: false,
        message: 'No data received',
        currencies: [],
      );
    } catch (e) {
      // On error, try to load from cache
      _currencies = cacheDataSource.getCachedCurrencies();
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
}
