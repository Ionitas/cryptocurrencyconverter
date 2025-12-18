import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Bottom bar with add currency and calculator buttons
class BottomBar extends StatelessWidget {
  final AppTheme appTheme;
  final VoidCallback onAddCurrency;
  final VoidCallback onShowCalculator;

  const BottomBar({
    super.key,
    required this.appTheme,
    required this.onAddCurrency,
    required this.onShowCalculator,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: appTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onAddCurrency,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: appTheme.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: appTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Add Currency',
                        style: TextStyle(
                          color: appTheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onShowCalculator,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: appTheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.calculate,
                    color: appTheme.textPrimary, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
