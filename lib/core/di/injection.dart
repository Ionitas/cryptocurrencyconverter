import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/crypto_api_datasource.dart';
import '../../data/datasources/fiat_api_datasource.dart';
import '../../data/datasources/local_cache_datasource.dart';
import '../../data/repositories/currency_repository_impl.dart';
import '../../domain/repositories/currency_repository.dart';
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

  // Data Sources
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
      cryptoDataSource: getIt<CryptoApiDataSource>(),
      fiatDataSource: getIt<FiatApiDataSource>(),
      cacheDataSource: getIt<LocalCacheDataSource>(),
    ),
  );
}
