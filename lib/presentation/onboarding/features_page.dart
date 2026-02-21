import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/services/analytics/tracking_service.dart';
import '../../core/services/analytics/firebase_analytics_service.dart';

/// Feature item data
class FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String emoji;

  const FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.emoji = '',
  });
}

/// Features showcase screen - second onboarding page
class FeaturesPage extends StatefulWidget {
  final AppTheme appTheme;
  final VoidCallback onContinue;

  const FeaturesPage({
    super.key,
    required this.appTheme,
    required this.onContinue,
  });

  @override
  State<FeaturesPage> createState() => _FeaturesPageState();
}

class _FeaturesPageState extends State<FeaturesPage>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _pulseController;
  late List<Animation<double>> _featureAnimations;

  static const List<FeatureItem> _features = [
    FeatureItem(
      icon: Icons.bolt_rounded,
      title: 'Real-time Rates',
      description: 'Live exchange rates updated constantly',
      color: Color(0xFF10B981),
      emoji: '⚡',
    ),
    FeatureItem(
      icon: Icons.currency_bitcoin_rounded,
      title: '225+ Currencies',
      description: 'Crypto, fiat & precious metals',
      color: Color(0xFFF59E0B),
      emoji: '🌍',
    ),
    FeatureItem(
      icon: Icons.calculate_rounded,
      title: 'Smart Calculator',
      description: 'Built-in calculator for quick math',
      color: Color(0xFF3B82F6),
      emoji: '🧮',
    ),
    FeatureItem(
      icon: Icons.cloud_off_rounded,
      title: 'Works Offline',
      description: 'Cached rates without internet',
      color: Color(0xFF8B5CF6),
      emoji: '📱',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _featureAnimations = List.generate(
      _features.length,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(
            0.1 + index * 0.15,
            0.4 + index * 0.15,
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = widget.appTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Column(
      children: [
        SizedBox(height: isSmallScreen ? 16 : 24),

        // Title with badge
        FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0, 0.3, curve: Curves.easeOut),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: appTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: appTheme.accent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: appTheme.accent,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Key Features',
                      style: TextStyle(
                        color: appTheme.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Text(
                'Powerful Features',
                style: TextStyle(
                  color: appTheme.textPrimary,
                  fontSize: isSmallScreen ? 26 : 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Everything you need in one app',
                style: TextStyle(
                  color: appTheme.textSecondary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: isSmallScreen ? 20 : 28),

        // Animated feature showcase
        Expanded(
          child: _buildFeatureShowcase(appTheme),
        ),

        // Continue button
        _buildContinueButton(appTheme),
      ],
    );
  }

  Widget _buildFeatureShowcase(AppTheme appTheme) {
    return ListView.builder(
      primary: false,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: _features.length,
      itemBuilder: (context, index) {
        final feature = _features[index];

        return AnimatedBuilder(
          animation: _featureAnimations[index],
          builder: (context, child) {
            final value = _featureAnimations[index].value;
            return Transform.translate(
              offset: Offset(40 * (1 - value), 0),
              child: Opacity(
                opacity: value,
                child: _buildFeatureCard(appTheme, feature, index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeatureCard(AppTheme appTheme, FeatureItem feature, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              appTheme.surface,
              appTheme.surface.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: feature.color.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: feature.color.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container with gradient
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    feature.color.withValues(alpha: 0.2),
                    feature.color.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: feature.color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  feature.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.title,
                    style: TextStyle(
                      color: appTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature.description,
                    style: TextStyle(
                      color: appTheme.textSecondary,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            // Check badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    feature.color,
                    feature.color.withValues(alpha: 0.8),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: feature.color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle continue button tap - request tracking permission then continue
  Future<void> _handleContinue() async {
    HapticFeedback.mediumImpact();

    // Log screen view
    await FirebaseAnalyticsService.instance.logScreenView(
      screenName: 'onboarding_features',
    );

    // Request App Tracking Transparency permission on iOS
    if (Platform.isIOS) {
      await TrackingService.instance.requestTrackingAuthorization();
    }

    // Continue to next page
    widget.onContinue();
  }

  Widget _buildContinueButton(AppTheme appTheme) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: DesignTokens.getBottomPadding(context) + 16,
      ),
      child: GestureDetector(
        onTap: _handleContinue,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                appTheme.primary,
                appTheme.primary.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: appTheme.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
