import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/supabase_config.dart';
import '../../data/datasources/crypto_api_datasource.dart';
import '../../data/datasources/supabase_datasource.dart';
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

  // Supabase Data Source (primary)
  getIt.registerLazySingleton<SupabaseDataSource>(
    () => SupabaseDataSource.instance(),
  );

  // Legacy Data Sources (fallback when Supabase is unavailable)
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
    () => CurrencyRepositoryImpl(
      supabaseDataSource:
          SupabaseConfig.isConfigured ? getIt<SupabaseDataSource>() : null,
      cryptoDataSource: getIt<CryptoApiDataSource>(),
      fiatDataSource: getIt<FiatApiDataSource>(),
      cacheDataSource: getIt<LocalCacheDataSource>(),
    ),
  );

  // Currency Sync Service (singleton for global state management)
  getIt.registerLazySingleton<CurrencySyncService>(
    () => CurrencySyncService(getIt<CurrencyRepository>()),
  );

  // Subscription Services
  getIt.registerSingleton<SubscriptionService>(SubscriptionService.instance);
  getIt.registerSingleton<SubscriptionManager>(SubscriptionManager.instance);

  // Initialize subscription manager
  await SubscriptionManager.instance.init();
}
