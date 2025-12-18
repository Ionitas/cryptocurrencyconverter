import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/currency.dart';
import 'currency_icon.dart';

/// Displays the main input section showing the amount being converted
class InputSection extends StatelessWidget {
  final Currency? selectedCurrency;
  final String displayValue;
  final String calculatorExpression;
  final AppTheme appTheme;
  final VoidCallback onTap;

  const InputSection({
    super.key,
    required this.selectedCurrency,
    required this.displayValue,
    required this.calculatorExpression,
    required this.appTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.shortestSide >= 600;
    final horizontalPadding = isTablet ? 24.0 : 16.0;
    final valueFontSize = isTablet ? 52.0 : 42.0;
    final labelFontSize = isTablet ? 16.0 : 14.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: ValueKey(selectedCurrency?.symbol ?? 'none'),
        margin:
            EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: appTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: appTheme.primary,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'You convert',
                  style: TextStyle(
                    color: appTheme.textSecondary,
                    fontSize: labelFontSize,
                  ),
                ),
                _buildCurrencyBadge(isTablet),
              ],
            ),
            const SizedBox(height: 8),
            // Main display value (shows full expression when available)
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      displayValue,
                      style: TextStyle(
                        color: appTheme.textPrimary,
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
            // Show expression hint when there's an active calculation
            if (calculatorExpression.isNotEmpty &&
                calculatorExpression != displayValue) ...[
              const SizedBox(height: 4),
              Text(
                calculatorExpression,
                style: TextStyle(
                  color: appTheme.textTertiary,
                  fontSize: labelFontSize - 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyBadge(bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 10,
        vertical: isTablet ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: appTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CurrencyIcon(currency: selectedCurrency, size: isTablet ? 24 : 20),
          const SizedBox(width: 6),
          Text(
            selectedCurrency?.symbol ?? '',
            style: TextStyle(
              color: appTheme.textPrimary,
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
