/// Analytics manager for tracking events
/// Use getIt<AnalyticsManager>() to access the singleton instance
class AnalyticsManager {
  /// Log a successful purchase event
  void logSuccesfullPurchase({
    required String currency,
    required double value,
    required String transactionId,
    required Map<String, dynamic> parameters,
  }) {
    // TODO: Implement analytics tracking (Firebase, Mixpanel, etc.)
    print('Purchase logged: $currency, $value, $transactionId, $parameters');
  }

  /// Log a general event
  void logEvent(String eventName, {Map<String, dynamic>? parameters}) {
    // TODO: Implement analytics tracking
    print('Event: $eventName, Parameters: $parameters');
  }

  /// Log screen view
  void logScreenView(String screenName) {
    // TODO: Implement analytics tracking
    print('Screen view: $screenName');
  }

  /// Log subscription paywall started event
  Future<void> logSubscriptionPaywallStarted({
    required Map<String, dynamic> parameters,
  }) async {
    // TODO: Implement analytics tracking
    print('Subscription paywall started: $parameters');
  }
}
