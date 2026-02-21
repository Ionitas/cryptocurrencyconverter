import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:purchases_flutter/purchases_flutter.dart' hide LogLevel;

import '../../config/env_config.dart';
import '../analytics/logging_system.dart';
import '../analytics/conversion_tracking_service.dart';
import 'subscription_config.dart';
import 'subscription_state.dart';

/// RevenueCat Purchases Service
/// Handles all subscription-related operations using RevenueCat SDK
class SubscriptionService extends ChangeNotifier {
  static SubscriptionService? _instance;
  static SubscriptionService get instance {
    _instance ??= SubscriptionService._();
    return _instance!;
  }

  SubscriptionService._();

  final ConversionTrackingService _conversionTracking =
      ConversionTrackingService.instance;

  // State
  SubscriptionState _state = const SubscriptionState();
  SubscriptionState get state => _state;

  // Initialization tracking
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  Completer<void>? _initializationCompleter;

  // Cache
  Offerings? _cachedOfferings;
  DateTime? _lastOfferingsFetch;
  CustomerInfo? _cachedCustomerInfo;
  DateTime? _lastCustomerInfoFetch;

  // Ongoing operations
  Future<void>? _ongoingInit;
  Future<Offerings?>? _ongoingOfferingsFetch;
  Future<CustomerInfo?>? _ongoingCustomerInfoFetch;

  /// Initialize the subscription service
  Future<void> init() async {
    // Return early if already initialized
    if (_isInitialized) {
      AppLogger.i('Subscription', 'Already initialized');
      return;
    }

    // If initialization is in progress, wait for it
    if (_initializationCompleter != null) {
      return _initializationCompleter!.future;
    }

    // If ongoing init exists, reuse it
    if (_ongoingInit != null) {
      return _ongoingInit;
    }

    _ongoingInit = _performInit();
    try {
      await _ongoingInit;
    } finally {
      _ongoingInit = null;
    }
  }

  Future<void> _performInit() async {
    _initializationCompleter = Completer<void>();

    try {
      AppLogger.i('Subscription', 'Initializing RevenueCat SDK...');
      final stopwatch = Stopwatch()..start();

      _setLoading(true);

      // Get the appropriate API key for the platform
      final apiKey = _getPlatformApiKey();
      if (apiKey.isEmpty) {
        throw const SubscriptionException(
          message: 'RevenueCat API key not configured for this platform',
        );
      }

      // Set log level
      await Purchases.setLogLevel(
          kDebugMode ? rc.LogLevel.verbose : rc.LogLevel.error);

      // Configure RevenueCat
      final configuration = PurchasesConfiguration(apiKey)
        ..shouldShowInAppMessagesAutomatically = true;

      await Purchases.configure(configuration)
          .timeout(SubscriptionConfig.initializationTimeout);

      // Set up customer info listener
      _setupCustomerInfoListener();

      // Fetch initial data
      await _getOfferings().timeout(const Duration(seconds: 10));

      // Fetch customer info in background
      _fetchCustomerInfoInBackground();

      _isInitialized = true;
      stopwatch.stop();

      AppLogger.s(
        'Subscription',
        'Initialized in ${stopwatch.elapsedMilliseconds}ms',
      );

      _initializationCompleter!.complete();
    } on TimeoutException catch (e) {
      AppLogger.e('Subscription', 'Initialization timed out', error: e);
      _setError('Initialization timed out');
      _initializationCompleter!.completeError(e);
      rethrow;
    } catch (e) {
      AppLogger.e('Subscription', 'Initialization failed', error: e);
      _setError('Failed to initialize subscription service');
      _initializationCompleter!.completeError(e);
      rethrow;
    } finally {
      _setLoading(false);
      _initializationCompleter = null;
    }
  }

  String _getPlatformApiKey() {
    if (Platform.isIOS || Platform.isMacOS) {
      return EnvConfig.revenueCatIosKey;
    } else if (Platform.isAndroid) {
      return EnvConfig.revenueCatAndroidKey;
    }
    return '';
  }

  void _setupCustomerInfoListener() {
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      AppLogger.i('Subscription', 'Customer info updated from listener');
      _updateCustomerInfo(customerInfo);
    });
  }

  void _fetchCustomerInfoInBackground() {
    _getCustomerInfo().catchError((e) {
      AppLogger.e('Subscription', 'Background customer info fetch failed',
          error: e);
      return null;
    });
  }

  /// Refresh subscription data
  Future<void> refresh({bool force = false}) async {
    try {
      await _ensureInitialized();

      if (_state.hasError) {
        _state = _state.copyWith(errorMessage: null);
        notifyListeners();
      }

      final futures = <Future<void>>[];

      if (force || _shouldRefreshOfferings()) {
        futures.add(_getOfferings());
      }

      if (force || _shouldRefreshCustomerInfo()) {
        futures.add(_getCustomerInfo().then((_) {}));
      }

      await Future.wait(futures);
    } catch (e) {
      AppLogger.e('Subscription', 'Refresh failed', error: e);
      _setError(SubscriptionConfig.fetchOfferingsError);
    }
  }

  bool _shouldRefreshOfferings() {
    return _cachedOfferings == null ||
        DateTime.now().difference(_lastOfferingsFetch ?? DateTime(0)) >
            SubscriptionConfig.offeringsCacheDuration;
  }

  bool _shouldRefreshCustomerInfo() {
    return _cachedCustomerInfo == null ||
        DateTime.now().difference(_lastCustomerInfoFetch ?? DateTime(0)) >
            SubscriptionConfig.customerInfoCacheDuration;
  }

  /// Get offerings from RevenueCat
  Future<Offerings?> _getOfferings() async {
    if (_ongoingOfferingsFetch != null) {
      return _ongoingOfferingsFetch;
    }

    _ongoingOfferingsFetch = _performOfferingsFetch();
    try {
      return await _ongoingOfferingsFetch;
    } finally {
      _ongoingOfferingsFetch = null;
    }
  }

  Future<Offerings?> _performOfferingsFetch() async {
    _setLoading(true);

    try {
      final offerings = await Purchases.getOfferings();

      _cachedOfferings = offerings;
      _lastOfferingsFetch = DateTime.now();
      _state = _state.copyWith(offerings: offerings);
      notifyListeners();

      if (offerings.current == null) {
        AppLogger.w('Subscription', 'No current offering found');
      } else {
        AppLogger.s('Subscription',
            'Loaded ${offerings.current!.availablePackages.length} packages');
      }

      return offerings;
    } on PlatformException catch (e) {
      AppLogger.e('Subscription', 'Failed to fetch offerings', error: e);
      _setError(SubscriptionConfig.fetchOfferingsError);
      return null;
    } catch (e) {
      AppLogger.e('Subscription', 'Failed to fetch offerings', error: e);
      _setError(SubscriptionConfig.fetchOfferingsError);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Get customer info from RevenueCat
  Future<CustomerInfo?> _getCustomerInfo({bool invalidateCache = false}) async {
    if (_ongoingCustomerInfoFetch != null) {
      return _ongoingCustomerInfoFetch;
    }

    _ongoingCustomerInfoFetch = _performCustomerInfoFetch(invalidateCache);
    try {
      return await _ongoingCustomerInfoFetch;
    } finally {
      _ongoingCustomerInfoFetch = null;
    }
  }

  Future<CustomerInfo?> _performCustomerInfoFetch(bool invalidateCache) async {
    if (!invalidateCache && !_shouldRefreshCustomerInfo()) {
      return _cachedCustomerInfo;
    }

    try {
      if (invalidateCache) {
        await Purchases.invalidateCustomerInfoCache();
      }

      final info = await Purchases.getCustomerInfo();
      _updateCustomerInfo(info);
      return info;
    } on PlatformException catch (e) {
      AppLogger.e('Subscription', 'Failed to fetch customer info', error: e);
      _setError(SubscriptionConfig.fetchCustomerInfoError);
      return null;
    } catch (e) {
      AppLogger.e('Subscription', 'Failed to fetch customer info', error: e);
      _setError(SubscriptionConfig.fetchCustomerInfoError);
      return null;
    }
  }

  void _updateCustomerInfo(CustomerInfo info) {
    _cachedCustomerInfo = info;
    _lastCustomerInfoFetch = DateTime.now();
    _state = _state.copyWith(customerInfo: info);
    notifyListeners();
  }

  /// Purchase a package
  Future<PurchaseResult?> purchase(Package package) async {
    await _ensureInitialized();

    _setLoading(true);
    try {
      // Validate purchase capability
      final canMakePayments = await Purchases.canMakePayments();
      if (!canMakePayments) {
        throw const SubscriptionException(
          message: 'Device cannot make payments',
          code: 'PAYMENT_CAPABILITY_ERROR',
        );
      }

      final result = await Purchases.purchase(PurchaseParams.package(package));
      _updateCustomerInfo(result.customerInfo);

      // Track conversion for GA4, Google Ads, SKAdNetwork (respects ATT)
      final hasTrial = package.storeProduct.introductoryPrice != null;
      if (hasTrial) {
        await _conversionTracking.trackTrialStart(package: package);
      } else {
        await _conversionTracking.trackPurchase(
          package: package,
          customerInfo: result.customerInfo,
        );
      }

      // Sync purchases in background
      Purchases.syncPurchases().catchError((e) {
        AppLogger.e('Subscription', 'Failed to sync purchases', error: e);
      });

      AppLogger.s('Subscription', 'Purchase successful');
      return result;
    } on PlatformException catch (e) {
      final message = _getPurchaseErrorMessage(e.code);
      AppLogger.e('Subscription', 'Purchase failed: ${e.code}', error: e);

      if (e.code == 'PURCHASE_CANCELLED_ERROR') {
        _setLoading(false);
        return null;
      }

      _setError(message);
      throw SubscriptionException(
          message: message, code: e.code, originalError: e);
    } catch (e) {
      AppLogger.e('Subscription', 'Purchase failed', error: e);
      _setError(SubscriptionConfig.purchaseError);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Handle purchase button tap with callbacks
  Future<void> handlePurchase({
    required Package package,
    required Function(PurchaseResult result, Package package) onSuccess,
    required Function(String message) onError,
  }) async {
    try {
      final result = await purchase(package);

      if (result != null &&
          (result.customerInfo.activeSubscriptions.isNotEmpty ||
              result.customerInfo.entitlements.active.containsKey('premium'))) {
        onSuccess(result, package);
      } else if (result != null) {
        onError('Purchase was not completed. Please try again.');
      }
      // result == null means cancelled, no callback needed
    } on SubscriptionException catch (e) {
      onError(e.message);
    } catch (e) {
      onError(SubscriptionConfig.purchaseError);
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    await _ensureInitialized();

    _setLoading(true);
    try {
      final info = await Purchases.restorePurchases();
      _updateCustomerInfo(info);

      final hasActiveSubscription = info.activeSubscriptions.isNotEmpty ||
          info.entitlements.active.containsKey('premium');

      // Track restore conversion
      if (hasActiveSubscription) {
        await _conversionTracking.trackRestore(customerInfo: info);
      }

      AppLogger.s(
          'Subscription', 'Restore complete, active: $hasActiveSubscription');

      return hasActiveSubscription;
    } on PlatformException catch (e) {
      AppLogger.e('Subscription', 'Restore failed', error: e);
      _setError(SubscriptionConfig.restoreError);
      return false;
    } catch (e) {
      AppLogger.e('Subscription', 'Restore failed', error: e);
      _setError(SubscriptionConfig.restoreError);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Check if user is premium (convenience method)
  bool get isPremium => _state.isPremium;

  /// Check if user is in trial
  bool get isTrial => _state.isTrial;

  /// Get available packages
  List<Package> get availablePackages => _state.availablePackages;

  /// Check if can add more currencies (free tier limit)
  bool canAddMoreCurrencies(int currentCount) {
    if (isPremium) return true;
    return currentCount < SubscriptionConfig.maxFreeCurrencies;
  }

  /// Check if can add more portfolio assets (free tier limit)
  bool canAddMoreAssets(int currentCount) {
    if (isPremium) return true;
    return currentCount < SubscriptionConfig.maxFreePortfolioAssets;
  }

  /// Ensure service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      if (_initializationCompleter != null) {
        await _initializationCompleter!.future;
      } else {
        await init();
      }
    }
  }

  void _setLoading(bool value) {
    _state = _state.copyWith(isLoading: value);
    notifyListeners();
  }

  void _setError(String message) {
    _state = _state.copyWith(errorMessage: message, isLoading: false);
    notifyListeners();
  }

  String _getPurchaseErrorMessage(String? code) {
    switch (code) {
      case 'PURCHASE_CANCELLED_ERROR':
        return 'Purchase was cancelled';
      case 'PURCHASE_NOT_ALLOWED_ERROR':
        return 'Purchases not allowed on this device';
      case 'PURCHASE_INVALID_ERROR':
        return 'Invalid purchase request';
      case 'PRODUCT_NOT_AVAILABLE_FOR_PURCHASE_ERROR':
        return 'Product not available';
      case 'PRODUCT_ALREADY_PURCHASED_ERROR':
        return 'Already purchased';
      case 'RECEIPT_ALREADY_IN_USE_ERROR':
        return 'Receipt already in use';
      case 'NETWORK_ERROR':
        return 'Network error, check connection';
      case 'STORE_PROBLEM_ERROR':
        return 'Store problem occurred';
      case 'PAYMENT_PENDING_ERROR':
        return 'Payment pending approval';
      default:
        return SubscriptionConfig.purchaseError;
    }
  }

  /// Reset the service (for testing/logout)
  Future<void> reset() async {
    try {
      if (_isInitialized) {
        await Purchases.logOut();
      }
    } catch (e) {
      AppLogger.e('Subscription', 'Error during logout', error: e);
    }

    _isInitialized = false;
    _initializationCompleter = null;
    _cachedOfferings = null;
    _lastOfferingsFetch = null;
    _cachedCustomerInfo = null;
    _lastCustomerInfoFetch = null;
    _state = const SubscriptionState();
    notifyListeners();

    AppLogger.i('Subscription', 'Service reset');
  }
}
