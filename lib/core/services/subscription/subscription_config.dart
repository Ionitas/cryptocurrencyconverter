/// Configuration and constants for subscription service
class SubscriptionConfig {
  SubscriptionConfig._();

  /// Entitlement identifier in RevenueCat
  static const String entitlementId = 'premium';

  /// Cache durations
  static const Duration offeringsCacheDuration = Duration(minutes: 30);
  static const Duration customerInfoCacheDuration = Duration(minutes: 5);

  /// Initialization timeout
  static const Duration initializationTimeout = Duration(seconds: 30);

  /// Max retry attempts for operations
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  /// Free tier limits
  static const int maxFreeCurrencies = 3;
  static const int maxFreePortfolioAssets = 2;

  /// App opens before showing paywall
  static const int appOpensBeforePaywall = 3;

  /// Error messages
  static const String fetchOfferingsError =
      'Unable to load subscription options';
  static const String fetchCustomerInfoError =
      'Unable to verify subscription status';
  static const String purchaseError = 'Purchase failed. Please try again.';
  static const String restoreError =
      'Failed to restore purchases. Please try again.';
}

/// Exception class for subscription-related errors
class SubscriptionException implements Exception {
  final String message;
  final String? code;
  final Object? originalError;

  const SubscriptionException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() =>
      'SubscriptionException: $message${code != null ? ' (code: $code)' : ''}';
}
