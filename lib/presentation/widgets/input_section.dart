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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: ValueKey(selectedCurrency?.symbol ?? 'none'),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
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
                  style: TextStyle(color: appTheme.textSecondary, fontSize: 14),
                ),
                if (calculatorExpression.isNotEmpty)
                  Text(
                    calculatorExpression,
                    style: TextStyle(
                      color: appTheme.textTertiary,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
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
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildCurrencyBadge(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: appTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CurrencyIcon(currency: selectedCurrency),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedCurrency?.symbol ?? '',
                style: TextStyle(
                  color: appTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                selectedCurrency?.name ?? '',
                style: TextStyle(
                  color: appTheme.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
