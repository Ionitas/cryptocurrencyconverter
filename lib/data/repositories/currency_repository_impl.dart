import '../../domain/models/currency.dart';
import '../../domain/repositories/currency_repository.dart';
import '../datasources/crypto_api_datasource.dart';
import '../datasources/fiat_api_datasource.dart';
import '../datasources/local_cache_datasource.dart';

/// Implementation of CurrencyRepository
class CurrencyRepositoryImpl implements CurrencyRepository {
  final CryptoApiDataSource cryptoDataSource;
  final FiatApiDataSource fiatDataSource;
  final LocalCacheDataSource cacheDataSource;

  List<Currency> _currencies = [];

  CurrencyRepositoryImpl({
    required this.cryptoDataSource,
    required this.fiatDataSource,
    required this.cacheDataSource,
  });

  @override
  List<Currency> get allCurrencies => _currencies;

  @override
  Future<LoadResult> loadCurrencies({bool forceRefresh = false}) async {
    // Try to use cache first
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

    // Fetch fresh data
    try {
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
          message: 'Fetched fresh data',
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
