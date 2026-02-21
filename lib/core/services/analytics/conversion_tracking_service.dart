import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'firebase_analytics_service.dart';
import 'logging_system.dart';
import 'tracking_service.dart';

/// Conversion tracking service for GA4, Google Ads, and SKAdNetwork
/// Only tracks conversions for users who have authorized tracking
class ConversionTrackingService {
  static ConversionTrackingService? _instance;
  static ConversionTrackingService get instance {
    _instance ??= ConversionTrackingService._();
    return _instance!;
  }

  ConversionTrackingService._();

  final TrackingService _trackingService = TrackingService.instance;
  final FirebaseAnalyticsService _firebaseAnalytics =
      FirebaseAnalyticsService.instance;

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    _isInitialized = true;
    AppLogger.s('ConversionTracking',
        'Initialized (SKAdNetwork handled by RevenueCat)');
  }

  bool get _shouldTrack {
    if (kIsWeb) return false;
    if (!Platform.isIOS && !Platform.isAndroid) return false;
    return _trackingService.isAuthorized;
  }

  Future<void> trackPurchase({
    required Package package,
    required CustomerInfo customerInfo,
  }) async {
    final product = package.storeProduct;
    final productId = product.identifier;
    final price = product.price;
    final currency = product.currencyCode;
    final period = _getSubscriptionPeriod(package.packageType);
    final hasTrial = product.introductoryPrice != null;

    if (_shouldTrack) {
      await _trackFirebasePurchase(
        productId: productId,
        productName: _getProductName(package),
        price: price,
        currency: currency,
        period: period,
        hasTrial: hasTrial,
        transactionId: customerInfo.originalAppUserId,
      );
    } else {
      AppLogger.i('ConversionTracking', 'Skipping tracking - not authorized');
    }

    await _trackRevenueCatConversion(
      package: package,
      customerInfo: customerInfo,
    );
  }

  Future<void> trackTrialStart({
    required Package package,
  }) async {
    final product = package.storeProduct;
    final productId = product.identifier;
    final currency = product.currencyCode;
    final period = _getSubscriptionPeriod(package.packageType);

    if (_shouldTrack) {
      await _firebaseAnalytics.logTrialStarted(
        productId: productId,
        productName: _getProductName(package),
        currency: currency,
        subscriptionPeriod: period,
      );
    }
  }

  Future<void> trackRestore({
    required CustomerInfo customerInfo,
  }) async {
    if (_shouldTrack) {
      await _firebaseAnalytics.logEvent(
        name: 'subscription_restored',
        parameters: {
          'user_id': customerInfo.originalAppUserId,
          'active_subscriptions': customerInfo.activeSubscriptions.join(','),
        },
      );
    }
  }

  Future<void> trackPaywallView({
    required String source,
    int currencyCount = 0,
    int portfolioCount = 0,
  }) async {
    if (_shouldTrack) {
      await _firebaseAnalytics.logPaywallView(
        source: source,
        currencyCount: currencyCount,
        portfolioCount: portfolioCount,
      );
    }
  }

  Future<void> trackPaywallResult({
    required String result,
    String? productId,
    String? errorMessage,
  }) async {
    if (_shouldTrack) {
      await _firebaseAnalytics.logPaywallResult(
        result: result,
        productId: productId,
        errorMessage: errorMessage,
      );
    }
  }

  Future<void> _trackFirebasePurchase({
    required String productId,
    required String productName,
    required double price,
    required String currency,
    required String period,
    required bool hasTrial,
    String? transactionId,
  }) async {
    await _firebaseAnalytics.logSubscriptionPurchase(
      productId: productId,
      productName: productName,
      price: price,
      currency: currency,
      subscriptionPeriod: period,
      hasFreeTrial: hasTrial,
      transactionId: transactionId,
    );

    await _firebaseAnalytics.setUserPremiumStatus(true);

    AppLogger.s('ConversionTracking', 'Firebase purchase tracked: $productId');
  }

  Future<void> _trackRevenueCatConversion({
    required Package package,
    required CustomerInfo customerInfo,
  }) async {
    try {
      final idfa = await _trackingService.getAdvertisingIdentifier();

      if (idfa != null && idfa.isNotEmpty) {
        await Purchases.setAttributes({
          'idfa': idfa,
        });
        AppLogger.s('ConversionTracking', 'IDFA attributed to RevenueCat');
      }

      await Purchases.collectDeviceIdentifiers();

      AppLogger.s('ConversionTracking',
          'RevenueCat conversion tracked (SKAdNetwork auto-handled)');
    } catch (e) {
      AppLogger.e('ConversionTracking', 'Failed to track RevenueCat conversion',
          error: e);
    }
  }

  String _getSubscriptionPeriod(PackageType type) {
    switch (type) {
      case PackageType.weekly:
        return 'weekly';
      case PackageType.monthly:
        return 'monthly';
      case PackageType.twoMonth:
        return '2_months';
      case PackageType.threeMonth:
        return '3_months';
      case PackageType.sixMonth:
        return '6_months';
      case PackageType.annual:
        return 'annual';
      case PackageType.lifetime:
        return 'lifetime';
      default:
        return 'unknown';
    }
  }

  String _getProductName(Package package) {
    final period = _getSubscriptionPeriod(package.packageType);
    return 'Premium $period';
  }
}
