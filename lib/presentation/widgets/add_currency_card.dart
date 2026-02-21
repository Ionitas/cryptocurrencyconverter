import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Card button to trigger adding a new currency
class AddCurrencyCard extends StatelessWidget {
  final AppTheme appTheme;
  final VoidCallback onTap;

  const AddCurrencyCard({
    super.key,
    required this.appTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: appTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: appTheme.primary.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: appTheme.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: appTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Add Currency',
              style: TextStyle(
                color: appTheme.primary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
