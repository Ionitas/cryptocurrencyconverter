import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics/logging_system.dart';
import 'subscription_config.dart';
import 'subscription_service.dart';

/// Manages subscription-related logic like paywall triggers, limits, etc.
class SubscriptionManager extends ChangeNotifier {
  static SubscriptionManager? _instance;
  static SubscriptionManager get instance {
    _instance ??= SubscriptionManager._();
    return _instance!;
  }

  SubscriptionManager._();

  static const String _appOpenCountKey = 'subscription_app_open_count';
  static const String _paywallShownKey = 'subscription_paywall_shown_today';
  static const String _lastPaywallDateKey = 'subscription_last_paywall_date';

  SharedPreferences? _prefs;
  int _appOpenCount = 0;
  bool _paywallShownThisSession = false;

  /// Initialize the manager
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _appOpenCount = _prefs?.getInt(_appOpenCountKey) ?? 0;
    AppLogger.i('SubscriptionManager', 'App open count: $_appOpenCount');
  }

  /// Increment app open count and check if paywall should show
  Future<bool> incrementAppOpenAndCheckPaywall() async {
    // Already shown this session
    if (_paywallShownThisSession) {
      return false;
    }

    // Premium users don't see paywall
    if (SubscriptionService.instance.isPremium) {
      return false;
    }

    _appOpenCount++;
    await _prefs?.setInt(_appOpenCountKey, _appOpenCount);

    AppLogger.i('SubscriptionManager',
        'App open count: $_appOpenCount, threshold: ${SubscriptionConfig.appOpensBeforePaywall}');

    // Check if it's time to show paywall (every 3rd open)
    if (_appOpenCount >= SubscriptionConfig.appOpensBeforePaywall) {
      // Reset counter
      _appOpenCount = 0;
      await _prefs?.setInt(_appOpenCountKey, 0);

      _paywallShownThisSession = true;
      return true;
    }

    return false;
  }

  /// Mark that paywall was shown this session (for non-counter triggers)
  void markPaywallShownThisSession() {
    _paywallShownThisSession = true;
  }

  /// Check if user has premium access
  bool get isPremium => SubscriptionService.instance.isPremium;

  /// Check if user can add more currencies (respects free tier limit)
  bool canAddMoreCurrencies(int currentCount) {
    return SubscriptionService.instance.canAddMoreCurrencies(currentCount);
  }

  /// Check if user can add more portfolio assets (respects free tier limit)
  bool canAddMoreAssets(int currentCount) {
    return SubscriptionService.instance.canAddMoreAssets(currentCount);
  }

  /// Get remaining currencies user can add
  int getRemainingCurrencies(int currentCount) {
    if (isPremium) return 999; // Unlimited
    final remaining = SubscriptionConfig.maxFreeCurrencies - currentCount;
    return remaining > 0 ? remaining : 0;
  }

  /// Get remaining assets user can add
  int getRemainingAssets(int currentCount) {
    if (isPremium) return 999; // Unlimited
    final remaining = SubscriptionConfig.maxFreePortfolioAssets - currentCount;
    return remaining > 0 ? remaining : 0;
  }

  /// Reset session state (for testing)
  void resetSession() {
    _paywallShownThisSession = false;
  }

  /// Reset all data (for testing)
  Future<void> resetAll() async {
    _appOpenCount = 0;
    _paywallShownThisSession = false;
    await _prefs?.setInt(_appOpenCountKey, 0);
    await _prefs?.remove(_paywallShownKey);
    await _prefs?.remove(_lastPaywallDateKey);
    AppLogger.i('SubscriptionManager', 'All data reset');
  }
}
