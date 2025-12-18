import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// Stage 3: Paywall placeholder screen
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
        // Close button
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, right: 16),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onClose();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: appTheme.surfaceLight.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: appTheme.textSecondary,
                  size: 24,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Premium icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                appTheme.accent,
                appTheme.primary,
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: appTheme.primary.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: 50,
          ),
        ),

        const SizedBox(height: 28),

        // Title
        Text(
          'Unlock Premium',
          style: TextStyle(
            color: appTheme.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Get unlimited access to all features',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: appTheme.textSecondary,
              fontSize: 16,
            ),
          ),
        ),

        const SizedBox(height: 36),

        // Features list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            children: [
              _buildFeatureItem(
                appTheme,
                Icons.all_inclusive,
                'Unlimited Conversions',
                'No limits on currency pairs',
              ),
              _buildFeatureItem(
                appTheme,
                Icons.notifications_active_rounded,
                'Price Alerts',
                'Get notified of rate changes',
              ),
              _buildFeatureItem(
                appTheme,
                Icons.history_rounded,
                'Historical Data',
                'View exchange rate history',
              ),
              _buildFeatureItem(
                appTheme,
                Icons.remove_circle_outline,
                'Ad-Free Experience',
                'No interruptions, ever',
              ),
              _buildFeatureItem(
                appTheme,
                Icons.sync_rounded,
                'Live Rates',
                'Real-time exchange updates',
              ),
            ],
          ),
        ),

        // Subscribe button (placeholder)
        _buildSubscribeButton(appTheme),

        // Skip text
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onClose();
            },
            child: Text(
              'Maybe later',
              style: TextStyle(
                color: appTheme.textTertiary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
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

  Widget _buildSubscribeButton(AppTheme appTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onSubscribe();
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    appTheme.primary,
                    appTheme.accent,
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: appTheme.primary.withOpacity(0.5),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Start Free Trial',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '7 days free, then \$4.99/month',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
