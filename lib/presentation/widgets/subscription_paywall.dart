import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/subscription/subscription_service.dart';
import '../../../core/services/analytics/logging_system.dart';
import '../utils/snackbar_helper.dart';
import 'cooldown_button.dart';

/// Subscription paywall widget
/// Shows subscription options and handles purchases
class SubscriptionPaywall extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onSuccess;
  final bool showCloseButton;
  final bool isOnboarding;

  const SubscriptionPaywall({
    super.key,
    this.onClose,
    this.onSuccess,
    this.showCloseButton = true,
    this.isOnboarding = false,
  });

  /// Show as a modal dialog
  static Future<bool> show(
    BuildContext context, {
    bool showCloseButton = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: SubscriptionPaywall(
          showCloseButton: showCloseButton,
          onClose: () => Navigator.of(context).pop(false),
          onSuccess: () => Navigator.of(context).pop(true),
        ),
      ),
    );
    return result ?? false;
  }

  @override
  State<SubscriptionPaywall> createState() => _SubscriptionPaywallState();
}

class _SubscriptionPaywallState extends State<SubscriptionPaywall>
    with SingleTickerProviderStateMixin {
  final AppTheme _appTheme = getIt<AppTheme>();
  final SubscriptionService _subscriptionService = SubscriptionService.instance;

  // URL placeholders - will be updated by user
  static const String _termsUrl =
      'https://currencycryptofiat.netlify.app/termscondition';
  static const String _privacyUrl =
      'https://currencycryptofiat.netlify.app/privacypolicy/';

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  Package? _selectedPackage;
  List<Package> _packages = [];

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animController.forward();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoading = true);

    try {
      // Ensure service is initialized
      if (!_subscriptionService.isInitialized) {
        await _subscriptionService.init();
      } else {
        await _subscriptionService.refresh();
      }

      final packages = _subscriptionService.availablePackages;

      if (mounted) {
        setState(() {
          _packages = packages;
          _isLoading = false;
          // Select annual by default if available, otherwise first
          _selectedPackage = packages.firstWhere(
            (p) => p.packageType == PackageType.annual,
            orElse: () => packages.isNotEmpty ? packages.first : packages.first,
          );
        });
      }
    } catch (e) {
      AppLogger.e('SubscriptionPaywall', 'Failed to load packages', error: e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handlePurchase() async {
    if (_selectedPackage == null) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    await _subscriptionService.handlePurchase(
      package: _selectedPackage!,
      onSuccess: (result, package) {
        AppLogger.s('SubscriptionPaywall', 'Purchase successful');
        if (mounted) {
          setState(() => _isLoading = false);
          SnackBarHelper.show(
            context: context,
            message: '🎉 Welcome to Premium!',
            appTheme: _appTheme,
            type: SnackBarType.success,
          );
          widget.onSuccess?.call();
        }
      },
      onError: (message) {
        if (mounted) {
          setState(() => _isLoading = false);
          SnackBarHelper.show(
            context: context,
            message: message,
            appTheme: _appTheme,
            type: SnackBarType.error,
          );
        }
      },
    );
  }

  Future<void> _handleRestore() async {
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    final success = await _subscriptionService.restorePurchases();

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        SnackBarHelper.show(
          context: context,
          message: '✓ Purchases restored successfully',
          appTheme: _appTheme,
          type: SnackBarType.success,
        );
        widget.onSuccess?.call();
      } else {
        SnackBarHelper.show(
          context: context,
          message: 'No active subscription found',
          appTheme: _appTheme,
          type: SnackBarType.info,
        );
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _buildContent(),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    // Calculate responsive max height based on screen size
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.85; // 85% of screen height

    return Container(
      constraints:
          BoxConstraints(maxWidth: 400, maxHeight: maxHeight.clamp(500, 750)),
      decoration: BoxDecoration(
        color: _appTheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            if (widget.showCloseButton) _buildCloseButton(),

            const SizedBox(height: 8),

            // Premium icon
            _buildPremiumIcon(),

            const SizedBox(height: 16),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Unlock Premium',
                  style: TextStyle(
                    color: _appTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Get unlimited access to all features',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _appTheme.textSecondary,
                  fontSize: 15,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Features list
            Flexible(
              child: SingleChildScrollView(
                primary: false,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildFeatureItem(
                      Icons.all_inclusive,
                      'Unlimited Currencies',
                      'Add as many currencies as you want',
                    ),
                    _buildFeatureItem(
                      Icons.pie_chart_rounded,
                      'Unlimited Portfolio',
                      'Track all your crypto assets',
                    ),
                    _buildFeatureItem(
                      Icons.sync_rounded,
                      'Live Rates',
                      'Real-time exchange updates',
                    ),
                    _buildFeatureItem(
                      Icons.remove_circle_outline,
                      'Ad-Free Experience',
                      'No interruptions, ever',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Package options
            if (!_isLoading && _packages.isNotEmpty) _buildPackageOptions(),

            const SizedBox(height: 16),

            // Subscribe button
            _buildSubscribeButton(),

            // Restore purchases
            _buildRestoreButton(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Align(
      alignment: Alignment.topLeft,
      child: CooldownButtonWidget(
        cooldownSeconds: 3,
        onTouch: () {
          HapticFeedback.lightImpact();
          widget.onClose?.call();
        },
        finishType: CooldownButtonFinishType.icon,
        loadingType: CooldownButtonLoadingType.text,
        textOnCountdown: '{s}s',
        iconAfterCountdown: Icons.close,
        color: _appTheme.textSecondary,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildPremiumIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _appTheme.primary.withValues(alpha: 0.4),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.asset(
          'assets/images/icon.png',
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _appTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _appTheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _appTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: _appTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: _appTheme.success, size: 20),
        ],
      ),
    );
  }

  Widget _buildPackageOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: _packages.map((package) {
          final isSelected = _selectedPackage?.identifier == package.identifier;
          return _buildPackageOption(package, isSelected);
        }).toList(),
      ),
    );
  }

  Widget _buildPackageOption(Package package, bool isSelected) {
    final priceString = package.storeProduct.priceString;
    final period = _getPackagePeriod(package.packageType);
    final isBestValue = package.packageType == PackageType.annual;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedPackage = package);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? _appTheme.primary.withValues(alpha: 0.1)
              : _appTheme.surfaceLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _appTheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _appTheme.primary : Colors.transparent,
                border: Border.all(
                  color:
                      isSelected ? _appTheme.primary : _appTheme.textTertiary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        period,
                        style: TextStyle(
                          color: _appTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isBestValue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _appTheme.success,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'BEST VALUE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (package.storeProduct.introductoryPrice != null)
                    Text(
                      'Free trial available',
                      style: TextStyle(
                        color: _appTheme.success,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              priceString,
              style: TextStyle(
                color: _appTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPackagePeriod(PackageType type) {
    switch (type) {
      case PackageType.weekly:
        return 'Weekly';
      case PackageType.monthly:
        return 'Monthly';
      case PackageType.twoMonth:
        return '2 Months';
      case PackageType.threeMonth:
        return '3 Months';
      case PackageType.sixMonth:
        return '6 Months';
      case PackageType.annual:
        return 'Annual';
      case PackageType.lifetime:
        return 'Lifetime';
      default:
        return 'Subscription';
    }
  }

  Widget _buildSubscribeButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: _isLoading ? null : _handlePurchase,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [_appTheme.primary, _appTheme.accent],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _appTheme.primary.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        _getSubscribeButtonText(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getSubscribeButtonText() {
    if (_selectedPackage?.storeProduct.introductoryPrice != null) {
      return 'Start Free Trial';
    }
    return 'Subscribe Now';
  }

  Widget _buildRestoreButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: [
          GestureDetector(
            onTap: () => _launchUrl(_termsUrl),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Terms',
                style: TextStyle(
                  color: _appTheme.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Text(
            '•',
            style: TextStyle(
              color: _appTheme.textTertiary,
              fontSize: 12,
            ),
          ),
          GestureDetector(
            onTap: _isLoading ? null : _handleRestore,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Restore',
                style: TextStyle(
                  color: _appTheme.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Text(
            '•',
            style: TextStyle(
              color: _appTheme.textTertiary,
              fontSize: 12,
            ),
          ),
          GestureDetector(
            onTap: () => _launchUrl(_privacyUrl),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Privacy',
                style: TextStyle(
                  color: _appTheme.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
