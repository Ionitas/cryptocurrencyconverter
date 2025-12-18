/// Mixin for advanced calculator logic with expression chaining
/// Supports operations like 2+2+2, evaluates only on equals
/// Respects operator precedence (×÷ before +-)
mixin CalculatorLogic {
  String displayValue = '0';
  String calculatorExpression = '';
  double currentAmount = 0;

  // Expression tokens: stores numbers and operators in sequence
  // e.g., ['2', '+', '3', '×', '4'] for "2+3×4"
  List<String> _expressionTokens = [];
  String _currentInput = '0';
  bool _justCalculated = false;

  /// Handles calculator button input
  void handleCalculatorInput(String value) {
    switch (value) {
      case 'C':
        _clear();
      case '⌫':
        _backspace();
      case '%':
        _percentage();
      case '+':
      case '-':
      case '×':
      case '÷':
        _handleOperation(value);
      case '=':
        _calculate();
      case '.':
        _decimal();
      default:
        _number(value);
    }
    _updateDisplay();
  }

  void _clear() {
    _expressionTokens = [];
    _currentInput = '0';
    currentAmount = 0;
    _justCalculated = false;
    calculatorExpression = '';
    displayValue = '0';
  }

  /// Resets calculator state when swapping currencies
  void resetCalculatorState() {
    _expressionTokens = [];
    _currentInput = displayValue;
    _justCalculated = true;
  }

  void _backspace() {
    if (_justCalculated) {
      _clear();
      return;
    }

    if (_currentInput.isNotEmpty &&
        _currentInput != '0' &&
        _currentInput.length > 0) {
      // Remove last character from current input
      if (_currentInput.length > 1) {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
        if (_currentInput == '-' || _currentInput.isEmpty) _currentInput = '0';
      } else {
        _currentInput = '0';
      }
    } else if (_expressionTokens.isNotEmpty) {
      // Pop from expression stack
      final last = _expressionTokens.removeLast();
      if (_isOperator(last) && _expressionTokens.isNotEmpty) {
        // Removed an operator, restore the previous number as current input
        _currentInput = _expressionTokens.removeLast();
      } else if (!_isOperator(last)) {
        // Removed a number
        _currentInput = last;
      }
    }
    currentAmount = double.tryParse(_currentInput) ?? 0;
  }

  void _percentage() {
    final currentValue = double.tryParse(_currentInput) ?? 0;

    if (_expressionTokens.isNotEmpty) {
      final validTokens = _getValidTokensForEval();
      if (validTokens.isNotEmpty) {
        final runningTotal = _evaluateExpression(validTokens);
        final percentValue = runningTotal * (currentValue / 100);
        _currentInput = formatCalculatorResult(percentValue);
      }
    } else {
      _currentInput = formatCalculatorResult(currentValue / 100);
    }
    currentAmount = double.tryParse(_currentInput) ?? 0;
  }

  void _handleOperation(String op) {
    if (_justCalculated) {
      // After calculation, start new expression with the result
      final numberToAdd = _currentInput.isNotEmpty ? _currentInput : '0';
      _expressionTokens = [numberToAdd, op];
      _currentInput = '';
      _justCalculated = false;
    } else if (_expressionTokens.isEmpty) {
      // First operation: number + operator
      final numberToAdd = _currentInput.isNotEmpty ? _currentInput : '0';
      _expressionTokens = [numberToAdd, op];
      _currentInput = '';
    } else if (_currentInput.isNotEmpty) {
      // We have a current input - add it and the operator
      _expressionTokens.add(_currentInput);
      _expressionTokens.add(op);
      _currentInput = '';
    } else if (_isOperator(_expressionTokens.last)) {
      // No current input and last token is operator - replace it
      _expressionTokens[_expressionTokens.length - 1] = op;
    } else {
      // Last token is a number, just add the operator
      _expressionTokens.add(op);
    }
  }

  void _calculate() {
    // Build complete expression
    List<String> tokensToEvaluate = List.from(_expressionTokens);

    // Add current input if available
    if (_currentInput.isNotEmpty) {
      tokensToEvaluate.add(_currentInput);
    }

    // Clean up - remove trailing operators
    while (tokensToEvaluate.isNotEmpty && _isOperator(tokensToEvaluate.last)) {
      tokensToEvaluate.removeLast();
    }

    if (tokensToEvaluate.isEmpty) {
      currentAmount = double.tryParse(_currentInput) ?? 0;
      _justCalculated = true;
      return;
    }

    // Single number - just use it
    if (tokensToEvaluate.length == 1) {
      _currentInput = tokensToEvaluate.first;
      currentAmount = double.tryParse(_currentInput) ?? 0;
      _expressionTokens = [];
      _justCalculated = true;
      return;
    }

    // Evaluate the full expression
    final result = _evaluateExpression(tokensToEvaluate);

    if (result.isNaN || result.isInfinite) {
      displayValue = 'Error';
      _clear();
      return;
    }

    _currentInput = formatCalculatorResult(result);
    currentAmount = result;
    _expressionTokens = [];
    _justCalculated = true;
  }

  /// Get valid tokens for evaluation (removes trailing operators)
  List<String> _getValidTokensForEval() {
    List<String> tokens = List.from(_expressionTokens);
    if (_currentInput.isNotEmpty) {
      tokens.add(_currentInput);
    }
    while (tokens.isNotEmpty && _isOperator(tokens.last)) {
      tokens.removeLast();
    }
    return tokens;
  }

  /// Evaluates expression with proper operator precedence (PEMDAS)
  double _evaluateExpression(List<String> tokens) {
    if (tokens.isEmpty) return 0;
    if (tokens.length == 1) return double.tryParse(tokens.first) ?? 0;

    // Filter out empty strings and create working copy
    List<String> expr = tokens.where((t) => t.isNotEmpty).toList();

    if (expr.isEmpty) return 0;
    if (expr.length == 1) return double.tryParse(expr.first) ?? 0;

    // Fix edge cases
    if (_isOperator(expr.first)) expr.insert(0, '0');
    while (expr.isNotEmpty && _isOperator(expr.last)) expr.removeLast();

    if (expr.isEmpty) return 0;
    if (expr.length == 1) return double.tryParse(expr.first) ?? 0;

    // First pass: × and ÷ (higher precedence)
    int i = 0;
    while (i < expr.length) {
      if (expr[i] == '×' || expr[i] == '÷') {
        if (i > 0 && i + 1 < expr.length) {
          final left = double.tryParse(expr[i - 1]) ?? 0;
          final right = double.tryParse(expr[i + 1]) ?? 0;
          final result = expr[i] == '×'
              ? left * right
              : (right != 0 ? left / right : double.nan);
          expr.replaceRange(i - 1, i + 2, [formatCalculatorResult(result)]);
          i = i - 1; // Stay at same logical position
        } else {
          i++;
        }
      } else {
        i++;
      }
    }

    if (expr.length == 1) return double.tryParse(expr.first) ?? 0;

    // Second pass: + and - (lower precedence)
    i = 0;
    while (i < expr.length) {
      if (expr[i] == '+' || expr[i] == '-') {
        if (i > 0 && i + 1 < expr.length) {
          final left = double.tryParse(expr[i - 1]) ?? 0;
          final right = double.tryParse(expr[i + 1]) ?? 0;
          final result = expr[i] == '+' ? left + right : left - right;
          expr.replaceRange(i - 1, i + 2, [formatCalculatorResult(result)]);
          i = i - 1;
        } else {
          i++;
        }
      } else {
        i++;
      }
    }

    return double.tryParse(expr.first) ?? 0;
  }

  void _decimal() {
    if (_justCalculated) {
      _expressionTokens = [];
      _currentInput = '0.';
      _justCalculated = false;
    } else if (_currentInput.isEmpty) {
      _currentInput = '0.';
    } else if (!_currentInput.contains('.')) {
      _currentInput += '.';
    }
    currentAmount = double.tryParse(_currentInput) ?? currentAmount;
  }

  void _number(String value) {
    if (_justCalculated) {
      // Fresh start after calculation
      _expressionTokens = [];
      _currentInput = value;
      _justCalculated = false;
    } else if (_currentInput.isEmpty) {
      // After operator, start new number
      _currentInput = value;
    } else if (_currentInput == '0' && value != '0') {
      // Replace leading zero
      _currentInput = value;
    } else if (_currentInput == '0' && value == '0') {
      // Don't add multiple leading zeros
    } else {
      // Append to current input
      _currentInput += value;
    }
    currentAmount = double.tryParse(_currentInput) ?? 0;
  }

  bool _isOperator(String token) {
    return token == '+' || token == '-' || token == '×' || token == '÷';
  }

  void _updateDisplay() {
    if (_expressionTokens.isEmpty) {
      calculatorExpression = '';
      displayValue = _currentInput.isEmpty ? '0' : _currentInput;
    } else {
      // Build full expression: tokens + current input
      String fullExpr = _expressionTokens.join(' ');
      if (_currentInput.isNotEmpty) {
        fullExpr += ' $_currentInput';
      }

      displayValue = fullExpr.isEmpty ? '0' : fullExpr;
      calculatorExpression = fullExpr;
    }

    // Update current amount for live currency conversion
    if (!_justCalculated) {
      final tokensForEval = _getValidTokensForEval();
      if (tokensForEval.isNotEmpty) {
        currentAmount = _evaluateExpression(tokensForEval);
      } else {
        currentAmount = double.tryParse(_currentInput) ?? 0;
      }
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
