/// Mixin for calculator logic handling
mixin CalculatorLogic {
  String displayValue = '0';
  String calculatorExpression = '';
  double? previousValue;
  String? operation;
  bool shouldResetDisplay = false;
  double currentAmount = 0;

  /// Handles calculator button input and returns the new state
  void handleCalculatorInput(String value) {
    switch (value) {
      case 'C':
        _clear();
        break;
      case '⌫':
        _backspace();
        break;
      case '%':
        _percentage();
        break;
      case '+':
      case '-':
      case '×':
      case '÷':
        _handleOperation(value);
        break;
      case '=':
        _calculate();
        break;
      case '.':
        _decimal();
        break;
      default:
        _number(value);
        break;
    }
  }

  void _clear() {
    displayValue = '0';
    calculatorExpression = '';
    previousValue = null;
    operation = null;
    currentAmount = 0;
    shouldResetDisplay = false;
  }

  void _backspace() {
    if (displayValue.length > 1) {
      displayValue = displayValue.substring(0, displayValue.length - 1);
      if (displayValue == '-') displayValue = '0';
    } else {
      displayValue = '0';
    }
    currentAmount = double.tryParse(displayValue) ?? 0;
  }

  void _percentage() {
    final currentValue = double.tryParse(displayValue) ?? 0;
    if (previousValue != null && operation != null) {
      final percentValue = previousValue! * (currentValue / 100);
      displayValue = formatCalculatorResult(percentValue);
    } else {
      displayValue = formatCalculatorResult(currentValue / 100);
    }
    currentAmount = double.tryParse(displayValue) ?? 0;
  }

  void _handleOperation(String op) {
    if (previousValue != null && operation != null && !shouldResetDisplay) {
      final currentValue = double.tryParse(displayValue) ?? 0;
      double result = calculateResult(previousValue!, currentValue, operation!);
      displayValue = formatCalculatorResult(result);
      previousValue = result;
      currentAmount = result;
    } else {
      previousValue = double.tryParse(displayValue) ?? 0;
    }
    operation = op;
    calculatorExpression = '$displayValue $op';
    shouldResetDisplay = true;
  }

  void _calculate() {
    if (previousValue != null && operation != null) {
      final currentValue = double.tryParse(displayValue) ?? 0;
      double result = calculateResult(previousValue!, currentValue, operation!);

      if (result.isNaN || result.isInfinite) {
        displayValue = 'Error';
        previousValue = null;
        operation = null;
        calculatorExpression = '';
        return;
      }

      displayValue = formatCalculatorResult(result);
      currentAmount = result;
      calculatorExpression = '';
      operation = null;
      previousValue = null;
      shouldResetDisplay = true;
    }
  }

  void _decimal() {
    if (shouldResetDisplay) {
      displayValue = '0.';
      shouldResetDisplay = false;
    } else if (!displayValue.contains('.')) {
      displayValue += '.';
    }
  }

  void _number(String value) {
    if (shouldResetDisplay || displayValue == '0') {
      displayValue = value;
      shouldResetDisplay = false;
    } else {
      displayValue += value;
    }
    currentAmount = double.tryParse(displayValue) ?? 0;

    if (operation != null && previousValue != null) {
      calculatorExpression =
          '${formatCalculatorResult(previousValue!)} $operation $displayValue';
    }
  }

  double calculateResult(double a, double b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        if (b != 0) return a / b;
        return double.nan;
      default:
        return b;
    }
  }

  String formatCalculatorResult(double value) {
    if (value == value.toInt() && value.abs() < 1e10) {
      return value.toInt().toString();
    }
    String result = value.toStringAsFixed(8);
    if (result.contains('.')) {
      result = result.replaceAll(RegExp(r'0+$'), '');
      result = result.replaceAll(RegExp(r'\.$'), '');
    }
    return result;
  }

  String formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)}K';
    } else if (amount >= 1) {
      return amount.toStringAsFixed(2);
    } else if (amount >= 0.0001) {
      return amount.toStringAsFixed(4);
    } else {
      return amount.toStringAsFixed(8);
    }
  }
}
