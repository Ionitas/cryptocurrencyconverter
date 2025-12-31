import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/subscription/subscription_service.dart';
import '../../core/services/analytics/logging_system.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/cooldown_button.dart';

/// Stage 3: Paywall screen for onboarding
class PaywallPage extends StatefulWidget {
  final AppTheme appTheme;
  final VoidCallback onClose;
  final VoidCallback onSubscribe;

  const PaywallPage({
    super.key,
    required this.appTheme,
    required this.onClose,
    required this.onSubscribe,
  });

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final SubscriptionService _subscriptionService = SubscriptionService.instance;

  // URL placeholders - will be updated by user
  static const String _termsUrl = 'https://example.com/terms';
  static const String _privacyUrl = 'https://example.com/privacy';

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
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
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
          // Select annual by default if available
          if (packages.isNotEmpty) {
            _selectedPackage = packages.firstWhere(
              (p) => p.packageType == PackageType.annual,
              orElse: () => packages.first,
            );
          }
        });
      }
    } catch (e) {
      AppLogger.e('PaywallPage', 'Failed to load packages', error: e);
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
        AppLogger.s('PaywallPage', 'Purchase successful');
        if (mounted) {
          setState(() => _isLoading = false);
          SnackBarHelper.show(
            context: context,
            message: '🎉 Welcome to Premium!',
            appTheme: widget.appTheme,
            type: SnackBarType.success,
          );
          widget.onSubscribe();
        }
      },
      onError: (message) {
        if (mounted) {
          setState(() => _isLoading = false);
          SnackBarHelper.show(
            context: context,
            message: message,
            appTheme: widget.appTheme,
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
          appTheme: widget.appTheme,
          type: SnackBarType.success,
        );
        widget.onSubscribe();
      } else {
        SnackBarHelper.show(
          context: context,
          message: 'No active subscription found',
          appTheme: widget.appTheme,
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
    final appTheme = widget.appTheme;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _buildContent(appTheme),
          ),
        );
      },
    );
  }

  Widget _buildContent(AppTheme appTheme) {
    return Column(
      children: [
        // Cooldown close button on the left
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, left: 8),
            child: CooldownButtonWidget(
              cooldownSeconds: 3,
              onTouch: () {
                HapticFeedback.lightImpact();
                widget.onClose();
              },
              finishType: CooldownButtonFinishType.icon,
              loadingType: CooldownButtonLoadingType.text,
              textOnCountdown: '{s}s',
              iconAfterCountdown: Icons.close,
              color: appTheme.textSecondary,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ),

        // Scrollable content with visible scrollbar
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            radius: const Radius.circular(4),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 4),

                  // App icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: appTheme.primary.withOpacity(0.4),
                          blurRadius: 25,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/icon.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Unlock All 225+ Currencies',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: appTheme.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Get real-time rates, unlimited conversions\n& premium features',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: appTheme.textSecondary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Features list
                  _buildFeatureItem(
                    appTheme,
                    Icons.all_inclusive,
                    'Unlimited Currencies',
                    'Add as many currencies as you want',
                  ),
                  _buildFeatureItem(
                    appTheme,
                    Icons.pie_chart_rounded,
                    'Unlimited Portfolio',
                    'Track all your crypto assets',
                  ),
                  _buildFeatureItem(
                    appTheme,
                    Icons.sync_rounded,
                    'Live Rates',
                    'Real-time exchange updates',
                  ),
                  _buildFeatureItem(
                    appTheme,
                    Icons.remove_circle_outline,
                    'Ad-Free Experience',
                    'No interruptions, ever',
                  ),

                  const SizedBox(height: 20),

                  // Package options
                  if (!_isLoading && _packages.isNotEmpty)
                    ...(_packages.map((package) {
                      final isSelected =
                          _selectedPackage?.identifier == package.identifier;
                      return _buildPackageOption(appTheme, package, isSelected);
                    }).toList()),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),

        // Subscribe button
        _buildSubscribeButton(appTheme),

        // Restore purchases + Terms + Privacy row
        Padding(
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
                      color: appTheme.textTertiary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Text(
                '•',
                style: TextStyle(
                  color: appTheme.textTertiary,
                  fontSize: 13,
                ),
              ),
              GestureDetector(
                onTap: _isLoading ? null : _handleRestore,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Restore',
                    style: TextStyle(
                      color: appTheme.textTertiary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Text(
                '•',
                style: TextStyle(
                  color: appTheme.textTertiary,
                  fontSize: 13,
                ),
              ),
              GestureDetector(
                onTap: () => _launchUrl(_privacyUrl),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Privacy',
                    style: TextStyle(
                      color: appTheme.textTertiary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFeatureItem(
    AppTheme appTheme,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: appTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: appTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: appTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: appTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: appTheme.success,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildPackageOption(
      AppTheme appTheme, Package package, bool isSelected) {
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
              ? appTheme.primary.withOpacity(0.1)
              : appTheme.surfaceLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? appTheme.primary : Colors.transparent,
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
                color: isSelected ? appTheme.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? appTheme.primary : appTheme.textTertiary,
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
                          color: appTheme.textPrimary,
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
                            color: appTheme.success,
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
                        color: appTheme.success,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              priceString,
              style: TextStyle(
                color: appTheme.textPrimary,
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

  Widget _buildSubscribeButton(AppTheme appTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                  colors: [
                    appTheme.primary,
                    appTheme.accent,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: appTheme.primary.withOpacity(0.5),
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
                    : Column(
                        children: [
                          Text(
                            _getSubscribeButtonText(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedPackage != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _selectedPackage!.storeProduct.priceString,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
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
}
