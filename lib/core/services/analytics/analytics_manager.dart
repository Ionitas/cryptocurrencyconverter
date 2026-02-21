import 'package:flutter/foundation.dart';

import 'firebase_analytics_service.dart';
import 'tracking_service.dart';
import 'logging_system.dart';

/// Analytics manager for tracking events
/// Use `getIt<AnalyticsManager>()` to access the singleton instance
class AnalyticsManager {
  final FirebaseAnalyticsService _firebaseAnalytics =
      FirebaseAnalyticsService.instance;
  final TrackingService _trackingService = TrackingService.instance;

  // Session tracking
  int _sessionNumber = 0;
  DateTime? _sessionStartTime;

  /// Initialize analytics services
  Future<void> init() async {
    try {
      await _firebaseAnalytics.init();
      AppLogger.s('AnalyticsManager', 'Initialized');
    } catch (e) {
      AppLogger.e('AnalyticsManager', 'Failed to initialize', error: e);
    }
  }

  /// Start a new session
  Future<void> startSession({String? source}) async {
    _sessionNumber++;
    _sessionStartTime = DateTime.now();
    await _firebaseAnalytics.logAppOpen(
      sessionNumber: _sessionNumber,
      source: source,
    );
  }

  /// End current session
  Future<void> endSession() async {
    if (_sessionStartTime != null) {
      final duration = DateTime.now().difference(_sessionStartTime!);
      await _firebaseAnalytics.logAppBackground(
        sessionDurationSeconds: duration.inSeconds,
      );
    }
  }

  /// Request app tracking authorization (iOS ATT)
  Future<void> requestTrackingAuthorization() async {
    await _trackingService.requestTrackingAuthorization();
  }

  /// Check if tracking is authorized
  bool get isTrackingAuthorized => _trackingService.isAuthorized;

  // =============================================
  // PURCHASE & SUBSCRIPTION ANALYTICS
  // =============================================

  /// Log a successful purchase event
  Future<void> logSuccesfullPurchase({
    required String currency,
    required double value,
    required String transactionId,
    required Map<String, dynamic> parameters,
  }) async {
    await _firebaseAnalytics.logPurchase(
      currency: currency,
      value: value,
      transactionId: transactionId,
    );

    if (kDebugMode) {
      debugPrint(
          'Purchase logged: $currency, $value, $transactionId, $parameters');
    }
  }

  /// Log paywall view
  Future<void> logPaywallView({
    required String source,
    int currencyCount = 0,
    int portfolioCount = 0,
  }) async {
    await _firebaseAnalytics.logPaywallView(
      source: source,
      currencyCount: currencyCount,
      portfolioCount: portfolioCount,
    );
  }

  /// Log paywall result
  Future<void> logPaywallResult({
    required String result,
    String? productId,
    String? errorMessage,
  }) async {
    await _firebaseAnalytics.logPaywallResult(
      result: result,
      productId: productId,
      errorMessage: errorMessage,
    );
  }

  /// Log subscription paywall started event
  Future<void> logSubscriptionPaywallStarted({
    required Map<String, dynamic> parameters,
  }) async {
    final params =
        parameters.map((key, value) => MapEntry(key, value as Object));
    await _firebaseAnalytics.logEvent(
      name: 'subscription_paywall_started',
      parameters: params,
    );

    if (kDebugMode) {
      debugPrint('Subscription paywall started: $parameters');
    }
  }

  // =============================================
  // GENERAL EVENTS
  // =============================================

  /// Log a general event
  Future<void> logEvent(String eventName,
      {Map<String, Object>? parameters}) async {
    await _firebaseAnalytics.logEvent(name: eventName, parameters: parameters);

    if (kDebugMode) {
      debugPrint('Event: $eventName, Parameters: $parameters');
    }
  }

  /// Log screen view
  Future<void> logScreenView(String screenName) async {
    await _firebaseAnalytics.logScreenView(screenName: screenName);

    if (kDebugMode) {
      debugPrint('Screen view: $screenName');
    }
  }

  // =============================================
  // ONBOARDING ANALYTICS
  // =============================================

  /// Log onboarding begin
  Future<void> logOnboardingBegin() async {
    await _firebaseAnalytics.logOnboardingBegin();
  }

  /// Log onboarding complete
  Future<void> logOnboardingComplete() async {
    await _firebaseAnalytics.logOnboardingComplete();
  }

  /// Log onboarding step
  Future<void> logOnboardingStep({
    required int stepNumber,
    required String stepName,
  }) async {
    await _firebaseAnalytics.logEvent(
      name: 'onboarding_step',
      parameters: {
        'step_number': stepNumber,
        'step_name': stepName,
      },
    );
  }

  // =============================================
  // CURRENCY & PORTFOLIO ANALYTICS
  // =============================================

  /// Log currency added
  Future<void> logCurrencyAdded(String currency) async {
    await _firebaseAnalytics.logCurrencyAdded(currency: currency);
  }

  /// Log currency removed
  Future<void> logCurrencyRemoved(String currency) async {
    await _firebaseAnalytics.logCurrencyRemoved(currency: currency);
  }

  /// Log currency conversion
  Future<void> logCurrencyConversion({
    required String from,
    required String to,
    required double amount,
  }) async {
    await _firebaseAnalytics.logCurrencyConversion(
      fromCurrency: from,
      toCurrency: to,
      amount: amount,
    );
  }

  /// Log portfolio asset added
  Future<void> logPortfolioAssetAdded({
    required String currency,
    required double amount,
  }) async {
    await _firebaseAnalytics.logPortfolioAssetAdded(
      currency: currency,
      amount: amount,
    );
  }

  /// Log portfolio asset removed
  Future<void> logPortfolioAssetRemoved(String currency) async {
    await _firebaseAnalytics.logPortfolioAssetRemoved(currency: currency);
  }

  // =============================================
  // PERFORMANCE ANALYTICS
  // =============================================

  /// Log data sync performance
  Future<void> logDataSync({
    required String source,
    required int durationMs,
    required int currencyCount,
    required bool success,
  }) async {
    await _firebaseAnalytics.logDataSync(
      source: source,
      durationMs: durationMs,
      currencyCount: currencyCount,
      success: success,
    );
  }

  /// Log startup performance
  Future<void> logStartupPerformance({
    required int totalDurationMs,
    Map<String, int>? taskDurations,
  }) async {
    await _firebaseAnalytics.logStartupPerformance(
      totalDurationMs: totalDurationMs,
      taskDurations: taskDurations ?? {},
    );
  }

  /// Log error
  Future<void> logError({
    required String errorType,
    required String message,
    String? stackTrace,
  }) async {
    await _firebaseAnalytics.logError(
      errorType: errorType,
      message: message,
      stackTrace: stackTrace,
    );
  }

  // =============================================
  // USER ENGAGEMENT ANALYTICS
  // =============================================

  /// Log feature usage
  Future<void> logFeatureUsage({
    required String feature,
    Map<String, Object>? details,
  }) async {
    await _firebaseAnalytics.logFeatureUsage(
      feature: feature,
      details: details,
    );
  }

  /// Log user engagement action
  Future<void> logUserEngagement({
    required String action,
    String? context,
  }) async {
    await _firebaseAnalytics.logUserEngagement(
      action: action,
      context: context,
    );
  }

  /// Log currency swapped (main ↔ list)
  Future<void> logCurrencySwapped({
    required String from,
    required String to,
    required double amount,
  }) async {
    await _firebaseAnalytics.logCurrencySwapped(
      from: from,
      to: to,
      amount: amount,
    );
  }

  /// Log currency reordered via drag
  Future<void> logCurrencyReordered() async {
    await _firebaseAnalytics.logCurrencyReordered();
  }

  /// Log calculator expression evaluated
  Future<void> logCalculatorUsed({
    required String expression,
    required double result,
  }) async {
    await _firebaseAnalytics.logCalculatorUsed(
      expression: expression,
      result: result,
    );
  }

  /// Log theme changed
  Future<void> logThemeChanged({required String theme}) async {
    await _firebaseAnalytics.logThemeChanged(theme: theme);
  }

  /// Log background sync completed
  Future<void> logBackgroundSyncComplete({
    required int currencyCount,
    required int durationMs,
  }) async {
    await _firebaseAnalytics.logBackgroundSyncComplete(
      currencyCount: currencyCount,
      durationMs: durationMs,
    );
  }

  // =============================================
  // USER PROPERTIES
  // =============================================

  /// Set user ID
  Future<void> setUserId(String? userId) async {
    await _firebaseAnalytics.setUserId(userId);
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _firebaseAnalytics.setUserProperty(name: name, value: value);
  }

  /// Set user premium status
  Future<void> setUserPremiumStatus(bool isPremium) async {
    await _firebaseAnalytics.setUserPremiumStatus(isPremium);
  }

  /// Set user country
  Future<void> setUserCountry(String? country) async {
    await _firebaseAnalytics.setUserCountry(country);
  }

  /// Set user currency preference
  Future<void> setUserCurrencyPreference(String currency) async {
    await _firebaseAnalytics.setUserCurrencyPreference(currency);
  }
}
