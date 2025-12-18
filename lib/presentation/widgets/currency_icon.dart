import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/models/currency.dart';

/// Displays a circular icon for a currency with its flag/symbol
class CurrencyIcon extends StatelessWidget {
  final Currency? currency;
  final double size;

  const CurrencyIcon({
    super.key,
    required this.currency,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (currency == null) return SizedBox(width: size, height: size);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: currency!.isCrypto
            ? AppColors.cryptoBackground
            : AppColors.fiatBackground,
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
