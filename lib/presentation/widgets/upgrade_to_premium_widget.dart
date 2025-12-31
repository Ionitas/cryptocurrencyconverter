import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/di/injection.dart';
import 'subscription_paywall.dart';

/// Widget that shows an upgrade to premium prompt
/// Used when user reaches free tier limits
class UpgradeToPremiumWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onUpgraded;

  const UpgradeToPremiumWidget({
    super.key,
    this.message = 'Upgrade to add more',
    this.onUpgraded,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = getIt<AppTheme>();

    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        final success = await SubscriptionPaywall.show(context);
        if (success) {
          onUpgraded?.call();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: appTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: appTheme.primary, width: 2),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: appTheme.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/images/icon.png',
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unlock All 150+ Currencies',
              style: TextStyle(
                color: appTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get real-time rates, unlimited conversions & premium charts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: appTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: appTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Upgrade to Pro',
                      style: TextStyle(
                        color: appTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward,
                        color: appTheme.textPrimary, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact version for inline use
class UpgradeToPremiumButton extends StatelessWidget {
  final VoidCallback? onUpgraded;

  const UpgradeToPremiumButton({
    super.key,
    this.onUpgraded,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = getIt<AppTheme>();

    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        final success = await SubscriptionPaywall.show(context);
        if (success) {
          onUpgraded?.call();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [appTheme.primary, appTheme.accent],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: appTheme.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Upgrade',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
