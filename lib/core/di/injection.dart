import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/crypto_api_datasource.dart';
import '../../data/datasources/fiat_api_datasource.dart';
import '../../data/datasources/local_cache_datasource.dart';
import '../../data/repositories/currency_repository_impl.dart';
import '../../domain/repositories/currency_repository.dart';
import '../services/analytics/analytics_manager.dart';
import '../services/config/config_service.dart';
import '../services/storage/storage_service.dart';
import '../services/currency_sync_service.dart';
import '../services/subscription/subscription_service.dart';
import '../services/subscription/subscription_manager.dart';
import '../theme/app_theme.dart';

/// Global GetIt instance for dependency injection
final getIt = GetIt.instance;

/// Sets up all dependencies using GetIt
Future<void> setupDependencies() async {
  // External dependencies
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // Theme
  getIt.registerSingleton<AppTheme>(AppTheme());

  // Core Services
  getIt.registerLazySingleton<StorageService>(() => StorageService());
  getIt.registerLazySingleton<ConfigService>(() => ConfigService());
  getIt.registerLazySingleton<AnalyticsManager>(() => AnalyticsManager());

  // Data Sources (direct API calls - no backend needed)
  getIt.registerLazySingleton<CryptoApiDataSource>(
    () => CryptoApiDataSource(),
  );
  getIt.registerLazySingleton<FiatApiDataSource>(
    () => FiatApiDataSource(),
  );
  getIt.registerLazySingleton<LocalCacheDataSource>(
    () => LocalCacheDataSource(getIt<SharedPreferences>()),
  );

  // Repositories
  getIt.registerLazySingleton<CurrencyRepository>(
    () {
      final repo = CurrencyRepositoryImpl(
        cryptoDataSource: getIt<CryptoApiDataSource>(),
        fiatDataSource: getIt<FiatApiDataSource>(),
        cacheDataSource: getIt<LocalCacheDataSource>(),
      );
      // Wire background-refresh callback so the sync service is notified
      // when the repository finishes a background update.
      // We do this lazily: the callback is set when CurrencySyncService is
      // first resolved (which happens after the repo is resolved).
      return repo;
    },
  );

  // Currency Sync Service (singleton for global state management)
  getIt.registerLazySingleton<CurrencySyncService>(
    () {
      final syncService = CurrencySyncService(getIt<CurrencyRepository>());
      // Wire repo → sync service notification for background refreshes
      final repo = getIt<CurrencyRepository>() as CurrencyRepositoryImpl;
      repo.onCurrenciesUpdated = () {
        syncService.notifyBackgroundUpdate(repo.allCurrencies);
      };
      return syncService;
    },
  );

  // Subscription Services
  getIt.registerSingleton<SubscriptionService>(SubscriptionService.instance);
  getIt.registerSingleton<SubscriptionManager>(SubscriptionManager.instance);

  // Initialize subscription manager
  await SubscriptionManager.instance.init();
}
