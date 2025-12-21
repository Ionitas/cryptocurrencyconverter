import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/currency.dart';
import '../../../widgets/currency_icon.dart';

/// Top section widget displaying total value and base currency selector
class PortfolioTotalSection extends StatelessWidget {
  final double total;
  final Currency? baseCurrency;
  final int entryCount;
  final String Function(double) formatAmount;
  final AppTheme appTheme;
  final VoidCallback onChangeCurrency;

  const PortfolioTotalSection({
    super.key,
    required this.total,
    required this.baseCurrency,
    required this.entryCount,
    required this.formatAmount,
    required this.appTheme,
    required this.onChangeCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.shortestSide >= 600;
    final valueFontSize = isTablet ? 52.0 : 42.0;
    final horizontalPadding = isTablet ? 24.0 : 16.0;

    return GestureDetector(
      onTap: onChangeCurrency,
      child: Container(
        margin:
            EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: appTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: appTheme.primary,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: appTheme.primary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildTotalAmount(valueFontSize),
            const SizedBox(height: 8),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: appTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: appTheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Total Balance',
              style: TextStyle(
                color: appTheme.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        _buildCurrencyBadge(),
      ],
    );
  }

  Widget _buildCurrencyBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: appTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: appTheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CurrencyIcon(currency: baseCurrency, size: 22),
          const SizedBox(width: 8),
          Text(
            baseCurrency?.symbol ?? '',
            style: TextStyle(
              color: appTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: appTheme.textTertiary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAmount(double fontSize) {
    return Row(
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatAmount(total),
              style: TextStyle(
                color: appTheme.textPrimary,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final currencyText = entryCount == 1 ? 'currency' : 'currencies';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: appTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$entryCount $currencyText',
            style: TextStyle(
              color: appTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        Text(
          'Tap to change currency',
          style: TextStyle(
            color: appTheme.textTertiary,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.touch_app_rounded,
          color: appTheme.textTertiary,
          size: 14,
        ),
      ],
    );
  }
}
