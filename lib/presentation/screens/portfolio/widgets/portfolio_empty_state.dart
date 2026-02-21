import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Empty state widget shown when no currencies are added
class PortfolioEmptyState extends StatelessWidget {
  final AppTheme appTheme;
  final VoidCallback onAddCurrency;

  const PortfolioEmptyState({
    super.key,
    required this.appTheme,
    required this.onAddCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: appTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: appTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              'Your portfolio is empty',
              style: TextStyle(
                color: appTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              'Add currencies with amounts to track\nyour total balance in any currency',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: appTheme.textTertiary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Add button
            GestureDetector(
              onTap: onAddCurrency,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: appTheme.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: appTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Add First Currency',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
