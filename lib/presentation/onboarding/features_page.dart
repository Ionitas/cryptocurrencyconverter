import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/analytics/tracking_service.dart';
import '../../core/services/analytics/firebase_analytics_service.dart';

/// Feature item data
class FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
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
      icon: Icons.speed_rounded,
      title: 'Real-time Rates',
      description: 'Live exchange rates updated every second',
      color: Color(0xFF10B981),
    ),
    FeatureItem(
      icon: Icons.currency_bitcoin_rounded,
      title: '150+ Currencies',
      description: 'Crypto, fiat & precious metals supported',
      color: Color(0xFFF59E0B),
    ),
    FeatureItem(
      icon: Icons.calculate_rounded,
      title: 'Smart Calculator',
      description: 'Built-in calculator for quick conversions',
      color: Color(0xFF3B82F6),
    ),
    FeatureItem(
      icon: Icons.offline_bolt_rounded,
      title: 'Works Offline',
      description: 'Cached rates available without internet',
      color: Color(0xFF8B5CF6),
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

    return Column(
      children: [
        const SizedBox(height: 20),

        // Title
        FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: _animController,
              curve: const Interval(0, 0.3, curve: Curves.easeOut),
            ),
          ),
          child: Column(
            children: [
              Text(
                'Powerful Features',
                style: TextStyle(
                  color: appTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Everything you need in one app',
                style: TextStyle(
                  color: appTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _features.length,
      itemBuilder: (context, index) {
        final feature = _features[index];

        return AnimatedBuilder(
          animation: _featureAnimations[index],
          builder: (context, child) {
            final value = _featureAnimations[index].value;
            return Transform.translate(
              offset: Offset(50 * (1 - value), 0),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          // Staggered pulse effect
          final pulseValue = (_pulseController.value + index * 0.2) % 1.0;
          final glowOpacity = 0.1 + (pulseValue * 0.1);

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: appTheme.surface.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: feature.color.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: feature.color.withOpacity(glowOpacity),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Animated icon container
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: feature.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    feature.icon,
                    color: feature.color,
                    size: 30,
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature.description,
                        style: TextStyle(
                          color: appTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Checkmark
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: feature.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: feature.color,
                    size: 18,
                  ),
                ),
              ],
            ),
          );
        },
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
      padding: const EdgeInsets.all(24),
      child: GestureDetector(
        onTap: _handleContinue,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: appTheme.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: appTheme.primary.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Text(
            'Continue',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
