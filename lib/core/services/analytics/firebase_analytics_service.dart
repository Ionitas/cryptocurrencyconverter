import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../firebase_options.dart';
import 'logging_system.dart';

/// Firebase Analytics Service
/// Handles all Firebase Analytics tracking
class FirebaseAnalyticsService {
  static FirebaseAnalyticsService? _instance;
  static FirebaseAnalyticsService get instance {
    _instance ??= FirebaseAnalyticsService._();
    return _instance!;
  }

  FirebaseAnalyticsService._();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;
  bool _isInitialized = false;

  /// Check if Firebase is initialized
  bool get isInitialized => _isInitialized;

  /// Get the analytics observer for navigation tracking
  FirebaseAnalyticsObserver? get observer => _observer;

  /// Initialize Firebase Analytics
  Future<void> init() async {
    if (_isInitialized) return;

    // Only initialize on mobile platforms
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) {
      AppLogger.i('FirebaseAnalytics', 'Skipping - not a mobile platform');
      return;
    }

    try {
      // Firebase should already be initialized in main.dart
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);

      // Set analytics collection enabled (can be toggled based on user consent)
      await _analytics!.setAnalyticsCollectionEnabled(true);

      _isInitialized = true;
      AppLogger.s('FirebaseAnalytics', 'Initialized successfully');
    } catch (e) {
      AppLogger.e('FirebaseAnalytics', 'Failed to initialize', error: e);
    }
  }

  /// Log a custom event
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!_isInitialized || _analytics == null) {
      if (kDebugMode) {
        debugPrint('Analytics Event: $name - $parameters');
      }
      return;
    }

    try {
      await _analytics!.logEvent(
        name: name,
        parameters: parameters,
      );
      AppLogger.d('FirebaseAnalytics', 'Event logged: $name');
    } catch (e) {
      AppLogger.e('FirebaseAnalytics', 'Failed to log event: $name', error: e);
    }
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_isInitialized || _analytics == null) {
      if (kDebugMode) {
        debugPrint('Screen View: $screenName');
      }
      return;
    }

    try {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      AppLogger.d('FirebaseAnalytics', 'Screen view: $screenName');
    } catch (e) {
      AppLogger.e('FirebaseAnalytics', 'Failed to log screen view', error: e);
    }
  }

  /// Log onboarding begin
  Future<void> logOnboardingBegin() async {
    await logEvent(name: 'tutorial_begin');
  }

  /// Log onboarding complete
  Future<void> logOnboardingComplete() async {
    await logEvent(name: 'tutorial_complete');
  }

  /// Log subscription screen view
  Future<void> logSubscriptionScreenView({String? source}) async {
    await logEvent(
      name: 'subscription_screen_view',
      parameters: {
        if (source != null) 'source': source,
      },
    );
  }

  /// Log subscription started
  Future<void> logSubscriptionStarted({
    required String productId,
    required String price,
  }) async {
    await logEvent(
      name: 'subscription_started',
      parameters: {
        'product_id': productId,
        'price': price,
      },
    );
  }

  /// Log purchase event
  Future<void> logPurchase({
    required String currency,
    required double value,
    String? transactionId,
    Map<String, Object>? additionalParams,
  }) async {
    if (!_isInitialized || _analytics == null) return;

    try {
      await _analytics!.logPurchase(
        currency: currency,
        value: value,
        transactionId: transactionId,
      );
      AppLogger.s('FirebaseAnalytics', 'Purchase logged: $value $currency');
    } catch (e) {
      AppLogger.e('FirebaseAnalytics', 'Failed to log purchase', error: e);
    }
  }

  /// Log GA4 e-commerce purchase event for conversion tracking
  /// This event is automatically synced to Google Ads when Firebase is linked
  Future<void> logEcommercePurchase({
    required String transactionId,
    required double value,
    required String currency,
    required List<Map<String, Object>> items,
    String? coupon,
    double? shipping,
    double? tax,
  }) async {
    if (!_isInitialized || _analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: 'purchase',
        parameters: {
          'transaction_id': transactionId,
          'value': value,
          'currency': currency,
          if (coupon != null) 'coupon': coupon,
          if (shipping != null) 'shipping': shipping,
          if (tax != null) 'tax': tax,
          'items': items,
        },
      );
      AppLogger.s('FirebaseAnalytics',
          'E-commerce purchase: $value $currency ($transactionId)');
    } catch (e) {
      AppLogger.e('FirebaseAnalytics', 'Failed to log e-commerce purchase',
          error: e);
    }
  }

  /// Log subscription purchase for GA4 conversions
  Future<void> logSubscriptionPurchase({
    required String productId,
    required String productName,
    required double price,
    required String currency,
    required String subscriptionPeriod,
    required bool hasFreeTrial,
    String? transactionId,
  }) async {
    if (!_isInitialized || _analytics == null) return;

    try {
      final items = [
        {
          'item_id': productId,
          'item_name': productName,
          'item_category': 'Subscription',
          'price': price,
          'quantity': 1,
        }
      ];

      await _analytics!.logEvent(
        name: 'purchase',
        parameters: {
          if (transactionId != null) 'transaction_id': transactionId,
          'value': price,
          'currency': currency,
          'items': items,
        },
      );

      await _analytics!.logEvent(
        name: 'subscription_purchase',
        parameters: {
          'product_id': productId,
          'product_name': productName,
          'price': price,
          'currency': currency,
          'subscription_period': subscriptionPeriod,
          'has_free_trial': hasFreeTrial ? 1 : 0,
        },
      );

      AppLogger.s('FirebaseAnalytics',
          'Subscription purchase: $productId - $price $currency');
    } catch (e) {
      AppLogger.e('FirebaseAnalytics', 'Failed to log subscription purchase',
          error: e);
    }
  }

  /// Log trial started event
  Future<void> logTrialStarted({
    required String productId,
    required String productName,
    required String currency,
    required String subscriptionPeriod,
  }) async {
    await logEvent(
      name: 'trial_started',
      parameters: {
        'product_id': productId,
        'product_name': productName,
        'currency': currency,
        'subscription_period': subscriptionPeriod,
      },
    );
  }

  /// Log trial converted to paid subscription
  Future<void> logTrialConverted({
    required String productId,
    required String currency,
  }) async {
    await logEvent(
      name: 'trial_converted',
      parameters: {
        'product_id': productId,
        'currency': currency,
      },
    );
  }

  /// Log currency conversion
  Future<void> logCurrencyConversion({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
  }) async {
    await logEvent(
      name: 'currency_conversion',
      parameters: {
        'from_currency': fromCurrency,
        'to_currency': toCurrency,
        'amount': amount,
      },
    );
  }

  /// Log currency added
  Future<void> logCurrencyAdded({required String currency}) async {
    await logEvent(
      name: 'currency_added',
      parameters: {'currency': currency},
    );
  }

  /// Log currency removed
  Future<void> logCurrencyRemoved({required String currency}) async {
    await logEvent(
      name: 'currency_removed',
      parameters: {'currency': currency},
    );
  }

  /// Log portfolio asset added
  Future<void> logPortfolioAssetAdded({
    required String currency,
    required double amount,
  }) async {
    await logEvent(
      name: 'portfolio_asset_added',
      parameters: {
        'currency': currency,
        'amount': amount,
      },
    );
  }

  /// Log portfolio asset removed
  Future<void> logPortfolioAssetRemoved({required String currency}) async {
    await logEvent(
      name: 'portfolio_asset_removed',
      parameters: {'currency': currency},
    );
  }

  /// Log app tracking authorization status
  Future<void> logTrackingAuthorizationStatus({
    required String status,
  }) async {
    await logEvent(
      name: 'tracking_authorization',
      parameters: {'status': status},
    );
  }

  // =============================================
  // APP LIFECYCLE & PERFORMANCE ANALYTICS
  // =============================================

  /// Log app open event with session info
  Future<void> logAppOpen({
    required int sessionNumber,
    String? source,
  }) async {
    await _analytics?.logAppOpen();
    await logEvent(
      name: 'app_session_start',
      parameters: {
        'session_number': sessionNumber,
        if (source != null) 'source': source,
      },
    );
  }

  /// Log app background event
  Future<void> logAppBackground({required int sessionDurationSeconds}) async {
    await logEvent(
      name: 'app_background',
      parameters: {
        'session_duration_seconds': sessionDurationSeconds,
      },
    );
  }

  /// Log data sync performance
  Future<void> logDataSync({
    required String source, // 'cache', 'api', 'network', 'background'
    required int durationMs,
    required int currencyCount,
    required bool success,
  }) async {
    await logEvent(
      name: 'data_sync',
      parameters: {
        'source': source,
        'duration_ms': durationMs,
        'currency_count': currencyCount,
        'success': success ? 1 : 0,
      },
    );
  }

  /// Log startup performance
  Future<void> logStartupPerformance({
    required int totalDurationMs,
    required Map<String, int> taskDurations,
  }) async {
    final params = <String, Object>{
      'total_duration_ms': totalDurationMs,
    };
    taskDurations.forEach((task, duration) {
      params['${task}_ms'] = duration;
    });

    await logEvent(
      name: 'app_startup_performance',
      parameters: params,
    );
  }

  /// Log error event
  Future<void> logError({
    required String errorType,
    required String message,
    String? stackTrace,
  }) async {
    await logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'message': message.substring(0, message.length.clamp(0, 100)),
        if (stackTrace != null) 'has_stack_trace': 1,
      },
    );
  }

  /// Log feature usage
  Future<void> logFeatureUsage({
    required String feature,
    Map<String, Object>? details,
  }) async {
    await logEvent(
      name: 'feature_usage',
      parameters: {
        'feature': feature,
        ...?details,
      },
    );
  }

  /// Log user engagement
  Future<void> logUserEngagement({
    required String action, // 'calculator_open', 'settings_open', 'refresh'
    String? context,
  }) async {
    await logEvent(
      name: 'user_engagement',
      parameters: {
        'action': action,
        if (context != null) 'context': context,
      },
    );
  }

  /// Log subscription paywall view
  Future<void> logPaywallView({
    required String source, // 'onboarding', 'limit_reached', 'periodic'
    required int currencyCount,
    required int portfolioCount,
  }) async {
    await logEvent(
      name: 'paywall_view',
      parameters: {
        'source': source,
        'currency_count': currencyCount,
        'portfolio_count': portfolioCount,
      },
    );
  }

  /// Log subscription paywall result
  Future<void> logPaywallResult({
    required String result, // 'purchased', 'restored', 'dismissed', 'error'
    String? productId,
    String? errorMessage,
  }) async {
    await logEvent(
      name: 'paywall_result',
      parameters: {
        'result': result,
        if (productId != null) 'product_id': productId,
        if (errorMessage != null)
          'error': errorMessage.substring(0, errorMessage.length.clamp(0, 50)),
      },
    );
  }

  /// Log currency swapped (main ↔ list)
  Future<void> logCurrencySwapped({
    required String from,
    required String to,
    required double amount,
  }) async {
    await logEvent(
      name: 'currency_swapped',
      parameters: {
        'from_currency': from,
        'to_currency': to,
        'amount': amount,
      },
    );
  }

  /// Log currency reordered via drag
  Future<void> logCurrencyReordered() async {
    await logEvent(name: 'currency_reordered');
  }

  /// Log calculator usage (expression evaluated)
  Future<void> logCalculatorUsed({
    required String expression,
    required double result,
  }) async {
    await logEvent(
      name: 'calculator_used',
      parameters: {
        'expression_length': expression.length,
        'result': result,
      },
    );
  }

  /// Log theme changed
  Future<void> logThemeChanged({required String theme}) async {
    await logEvent(
      name: 'theme_changed',
      parameters: {'theme': theme},
    );
  }

  /// Log background sync completed
  Future<void> logBackgroundSyncComplete({
    required int currencyCount,
    required int durationMs,
  }) async {
    await logEvent(
      name: 'background_sync_complete',
      parameters: {
        'currency_count': currencyCount,
        'duration_ms': durationMs,
      },
    );
  }

  // =============================================
  // ONBOARDING FUNNEL ANALYTICS (ENHANCED)
  // =============================================

  /// Log onboarding step with timing data
  Future<void> logOnboardingStepWithTiming({
    required int stepNumber,
    required String stepName,
    required int durationMs,
  }) async {
    await logEvent(
      name: 'onboarding_step_timed',
      parameters: {
        'step_number': stepNumber,
        'step_name': stepName,
        'duration_ms': durationMs,
      },
    );
  }

  /// Log country selected during onboarding
  Future<void> logOnboardingCountrySelected({
    required String countryCode,
    required String countryName,
    required bool wasAutoDetected,
  }) async {
    await logEvent(
      name: 'onboarding_country_selected',
      parameters: {
        'country_code': countryCode,
        'country_name': countryName,
        'auto_detected': wasAutoDetected ? 1 : 0,
      },
    );
  }

  /// Log purpose selected during onboarding
  Future<void> logOnboardingPurposeSelected({
    required String purpose,
  }) async {
    await logEvent(
      name: 'onboarding_purpose_selected',
      parameters: {
        'purpose': purpose,
      },
    );
  }

  /// Log total onboarding completion time
  Future<void> logOnboardingCompleteTimed({
    required int totalDurationSeconds,
    required String? countryCode,
    required String? purpose,
  }) async {
    await logEvent(
      name: 'onboarding_complete_timed',
      parameters: {
        'total_duration_seconds': totalDurationSeconds,
        if (countryCode != null) 'country_code': countryCode,
        if (purpose != null) 'purpose': purpose,
      },
    );
  }

  // =============================================
  // ATT / TRACKING ANALYTICS (ENHANCED)
  // =============================================

  /// Log ATT prompt shown event
  Future<void> logAttPromptShown() async {
    await logEvent(name: 'att_prompt_shown');
  }

  /// Log ATT prompt result with timing
  Future<void> logAttPromptResult({
    required String status,
    required int responseTimeMs,
    required bool wasFirstRequest,
  }) async {
    await logEvent(
      name: 'att_prompt_result',
      parameters: {
        'status': status,
        'response_time_ms': responseTimeMs,
        'first_request': wasFirstRequest ? 1 : 0,
      },
    );
  }

  // =============================================
  // PAYWALL ANALYTICS (ENHANCED)
  // =============================================

  /// Log paywall loaded with package details
  Future<void> logPaywallLoaded({
    required String source,
    required int packageCount,
    required int loadDurationMs,
  }) async {
    await logEvent(
      name: 'paywall_loaded',
      parameters: {
        'source': source,
        'package_count': packageCount,
        'load_duration_ms': loadDurationMs,
      },
    );
  }

  /// Log paywall close button tapped (distinct from dismissed)
  Future<void> logPaywallCloseTapped({
    required String source,
    required int timeSpentSeconds,
  }) async {
    await logEvent(
      name: 'paywall_close_tapped',
      parameters: {
        'source': source,
        'time_spent_seconds': timeSpentSeconds,
      },
    );
  }

  /// Log paywall subscribe/CTA button tapped
  Future<void> logPaywallCtaTapped({
    required String source,
    required String productId,
    required String packageType,
  }) async {
    await logEvent(
      name: 'paywall_cta_tapped',
      parameters: {
        'source': source,
        'product_id': productId,
        'package_type': packageType,
      },
    );
  }

  /// Log paywall package selected
  Future<void> logPaywallPackageSelected({
    required String source,
    required String productId,
    required String packageType,
    required String price,
  }) async {
    await logEvent(
      name: 'paywall_package_selected',
      parameters: {
        'source': source,
        'product_id': productId,
        'package_type': packageType,
        'price': price,
      },
    );
  }

  /// Log paywall restore tapped
  Future<void> logPaywallRestoreTapped({
    required String source,
  }) async {
    await logEvent(
      name: 'paywall_restore_tapped',
      parameters: {
        'source': source,
      },
    );
  }

  // =============================================
  // CURRENCY USAGE ANALYTICS (ENHANCED)
  // =============================================

  /// Log currency search query in add-currency modal
  Future<void> logCurrencySearch({
    required String query,
    required int resultCount,
  }) async {
    await logEvent(
      name: 'currency_search',
      parameters: {
        'query': query.substring(0, query.length.clamp(0, 50)),
        'result_count': resultCount,
      },
    );
  }

  /// Set user property for most-used currency pair
  Future<void> setMostUsedCurrencyPair(String pair) async {
    await setUserProperty(name: 'top_currency_pair', value: pair);
  }

  /// Set user property for total currencies count
  Future<void> setUserCurrencyCount(int count) async {
    await setUserProperty(name: 'currency_count', value: count.toString());
  }

  /// Log session conversion count
  Future<void> logSessionConversionCount({
    required int count,
  }) async {
    await logEvent(
      name: 'session_conversion_count',
      parameters: {
        'count': count,
      },
    );
  }

  // =============================================
  // AD ATTRIBUTION & CAMPAIGN TRACKING
  // =============================================

  /// Log campaign source for Google Ads attribution
  Future<void> logCampaignAttribution({
    String? source,
    String? medium,
    String? campaign,
  }) async {
    await logEvent(
      name: 'campaign_attribution',
      parameters: {
        if (source != null) 'source': source,
        if (medium != null) 'medium': medium,
        if (campaign != null) 'campaign': campaign,
      },
    );
  }

  /// Log first open event with install attribution data
  Future<void> logFirstOpen({
    required String platform,
    String? installSource,
  }) async {
    await logEvent(
      name: 'first_open_attributed',
      parameters: {
        'platform': platform,
        if (installSource != null) 'install_source': installSource,
      },
    );
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (!_isInitialized || _analytics == null) return;

    try {
      await _analytics!.setUserProperty(name: name, value: value);
    } catch (e) {
      AppLogger.e('FirebaseAnalytics', 'Failed to set user property', error: e);
    }
  }

  /// Set user ID for analytics
  Future<void> setUserId(String? userId) async {
    if (!_isInitialized || _analytics == null) return;

    try {
      await _analytics!.setUserId(id: userId);
    } catch (e) {
      AppLogger.e('FirebaseAnalytics', 'Failed to set user ID', error: e);
    }
  }

  /// Set user premium status
  Future<void> setUserPremiumStatus(bool isPremium) async {
    await setUserProperty(
        name: 'is_premium', value: isPremium ? 'true' : 'false');
  }

  /// Set user currency preference
  Future<void> setUserCurrencyPreference(String currency) async {
    await setUserProperty(name: 'preferred_currency', value: currency);
  }

  /// Set user country
  Future<void> setUserCountry(String? country) async {
    await setUserProperty(name: 'user_country', value: country);
  }

  /// Enable/disable analytics collection
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    if (!_isInitialized || _analytics == null) return;

    try {
      await _analytics!.setAnalyticsCollectionEnabled(enabled);
      AppLogger.i('FirebaseAnalytics', 'Collection enabled: $enabled');
    } catch (e) {
      AppLogger.e('FirebaseAnalytics', 'Failed to toggle collection', error: e);
    }
  }
}
