import 'package:flutter/material.dart';
import '../../core/di/injection.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../domain/models/currency.dart';

/// Displays a circular icon for a currency with its flag/symbol
class CurrencyIcon extends StatelessWidget {
  final Currency? currency;
  final double size;

  const CurrencyIcon({
    super.key,
    required this.currency,
    this.size = DesignTokens.currencyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (currency == null) return SizedBox(width: size, height: size);

    final appTheme = getIt<AppTheme>();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: currency!.isCrypto ? appTheme.cryptoBackground : appTheme.fiatBackground,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          currency!.displayFlag,
          style: TextStyle(
            fontSize: size * 0.55,
          ),
        ),
      ),
    );
  }
}
