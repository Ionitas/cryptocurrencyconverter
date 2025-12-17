import 'package:intl/intl.dart';

class NumberFormatter {
  /// Formats a number for display with thousands separators
  /// Used for currency conversion display
  static String formatDisplay(double value) {
    if (value.isNaN || value.isInfinite) {
      return '0';
    }

    if (value == value.toInt()) {
      final formatter = NumberFormat.decimalPattern();
      return formatter.format(value.toInt());
    }

    if (value.abs() < 0.01 && value != 0) {
      final formatted = value.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');

      final formatter = NumberFormat.decimalPattern();
      final parts = formatted.split('.');
      if (parts.length == 2) {
        return '${formatter.format(double.parse(parts[0]))}.${parts[1]}';
      }
      return formatter.format(double.parse(formatted));
    }

    final rounded = double.parse(value.toStringAsFixed(2));
    final formatter = NumberFormat.decimalPattern();
    formatter.minimumFractionDigits = 2;
    formatter.maximumFractionDigits = 2;
    return formatter.format(rounded);
  }

  /// Formats a number for calculator results (without thousands separators)
  /// Used for calculator display
  static String formatResult(double value) {
    if (value.isNaN || value.isInfinite) {
      return '0';
    }

    if (value.abs() < 0.01 && value != 0) {
      return value.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }

    final rounded = double.parse(value.toStringAsFixed(2));
    if (rounded == rounded.toInt()) {
      return rounded.toInt().toString();
    }
    return rounded.toString();
  }
}
