import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Premium upgrade promotion card
class PremiumCard extends StatelessWidget {
  final AppTheme appTheme;
  final VoidCallback onUpgrade;

  const PremiumCard({
    super.key,
    required this.appTheme,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: appTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: appTheme.primary, width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: appTheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium,
              color: appTheme.primary,
              size: 32,
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
            child: ElevatedButton(
              onPressed: onUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
    );
  }
}
