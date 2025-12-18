import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/currency.dart';
import 'currency_icon.dart';

/// Displays a currency conversion card that can be reordered and dismissed
class CurrencyCard extends StatelessWidget {
  final Currency currency;
  final Currency selectedCurrency;
  final int index;
  final double convertedAmount;
  final double exchangeRate;
  final AppTheme appTheme;
  final VoidCallback onTap;
  final VoidCallback onDismissed;
  final VoidCallback onUndo;
  final String Function(double) formatAmount;

  const CurrencyCard({
    super.key,
    required this.currency,
    required this.selectedCurrency,
    required this.index,
    required this.convertedAmount,
    required this.exchangeRate,
    required this.appTheme,
    required this.onTap,
    required this.onDismissed,
    required this.onUndo,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('dismissible_${currency.symbol}'),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        onDismissed();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${currency.symbol} removed'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: onUndo,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: appTheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.drag_indicator,
                    color: appTheme.primaryLight,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CurrencyIcon(currency: currency),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currency.symbol,
                      style: TextStyle(
                        color: appTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      currency.name,
                      style: TextStyle(
                        color: appTheme.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatAmount(convertedAmount),
                    style: TextStyle(
                      color: appTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '1 ${selectedCurrency.symbol} = ${formatAmount(exchangeRate)} ${currency.symbol}',
                    style: TextStyle(
                      color: appTheme.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
