import 'package:purchases_flutter/purchases_flutter.dart';

/// State class for subscription service
class SubscriptionState {
  final bool isLoading;
  final String? errorMessage;
  final Offerings? offerings;
  final CustomerInfo? customerInfo;

  const SubscriptionState({
    this.isLoading = false,
    this.errorMessage,
    this.offerings,
    this.customerInfo,
  });

  /// Check if user has premium access
  bool get isPremium {
    if (customerInfo == null) return false;
    return customerInfo!.entitlements.active.containsKey('premium') ||
        customerInfo!.activeSubscriptions.isNotEmpty;
  }

  /// Check if user is in trial period
  bool get isTrial {
    if (customerInfo == null) return false;
    final premiumEntitlement = customerInfo!.entitlements.active['premium'];
    if (premiumEntitlement == null) return false;
    return premiumEntitlement.periodType == PeriodType.trial;
  }

  /// Check if there's an error
  bool get hasError => errorMessage != null;

  /// Get the current offering
  Offering? get currentOffering => offerings?.current;

  /// Get weekly package
  Package? get weeklyPackage => currentOffering?.weekly;

  /// Get monthly package
  Package? get monthlyPackage => currentOffering?.monthly;

  /// Get annual package
  Package? get annualPackage => currentOffering?.annual;

  /// Get lifetime package (if available)
  Package? get lifetimePackage => currentOffering?.lifetime;

  /// Get all available packages
  List<Package> get availablePackages =>
      currentOffering?.availablePackages ?? [];

  /// Copy with method for state updates
  SubscriptionState copyWith({
    bool? isLoading,
    String? errorMessage,
    Offerings? offerings,
    CustomerInfo? customerInfo,
  }) {
    return SubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      offerings: offerings ?? this.offerings,
      customerInfo: customerInfo ?? this.customerInfo,
    );
  }
}
