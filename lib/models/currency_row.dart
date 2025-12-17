import 'currency.dart';

class CurrencyRow {
  final Currency currency;
  final String displayValue;
  final bool isActive;

  const CurrencyRow({
    required this.currency,
    required this.displayValue,
    this.isActive = false,
  });

  CurrencyRow copyWith({
    Currency? currency,
    String? displayValue,
    bool? isActive,
  }) {
    return CurrencyRow(
      currency: currency ?? this.currency,
      displayValue: displayValue ?? this.displayValue,
      isActive: isActive ?? this.isActive,
    );
  }

  double? get numericValue {
    if (displayValue.isEmpty) return null;
    return double.tryParse(displayValue);
  }
}
