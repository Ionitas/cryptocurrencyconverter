import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Calculator keypad widget for inputting amounts
class CalculatorPad extends StatelessWidget {
  final AppTheme appTheme;
  final Function(String) onInput;
  final VoidCallback onHide;

  const CalculatorPad({
    super.key,
    required this.appTheme,
    required this.onInput,
    required this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: appTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle indicator
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: appTheme.primaryLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Calculator buttons
            _buildButtonRow([
              'C',
              '⌫',
              '%',
              '÷'
            ], [
              _ButtonType.function,
              _ButtonType.function,
              _ButtonType.function,
              _ButtonType.operation
            ]),
            const SizedBox(height: 8),
            _buildButtonRow([
              '7',
              '8',
              '9',
              '×'
            ], [
              _ButtonType.number,
              _ButtonType.number,
              _ButtonType.number,
              _ButtonType.operation
            ]),
            const SizedBox(height: 8),
            _buildButtonRow([
              '4',
              '5',
              '6',
              '-'
            ], [
              _ButtonType.number,
              _ButtonType.number,
              _ButtonType.number,
              _ButtonType.operation
            ]),
            const SizedBox(height: 8),
            _buildButtonRow([
              '1',
              '2',
              '3',
              '+'
            ], [
              _ButtonType.number,
              _ButtonType.number,
              _ButtonType.number,
              _ButtonType.operation
            ]),
            const SizedBox(height: 8),
            _buildButtonRow([
              'hide',
              '0',
              '.',
              '='
            ], [
              _ButtonType.hide,
              _ButtonType.number,
              _ButtonType.number,
              _ButtonType.equals
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonRow(List<String> values, List<_ButtonType> types) {
    return Row(
      children: List.generate(values.length, (index) {
        return _buildCalcButton(values[index], types[index]);
      }),
    );
  }

  Widget _buildCalcButton(String value, _ButtonType type) {
    Color backgroundColor;
    Color textColor = appTheme.textPrimary;

    switch (type) {
      case _ButtonType.operation:
        backgroundColor = appTheme.primary;
        break;
      case _ButtonType.function:
        backgroundColor = appTheme.surfaceLight;
        textColor = appTheme.textLight;
        break;
      case _ButtonType.equals:
        backgroundColor = appTheme.accent;
        break;
      case _ButtonType.hide:
        backgroundColor = appTheme.surfaceLight;
        break;
      case _ButtonType.number:
        backgroundColor = appTheme.background;
        break;
    }

    Widget buttonContent;
    if (type == _ButtonType.hide) {
      buttonContent = Icon(
        Icons.keyboard_hide_rounded,
        color: appTheme.textLight,
        size: 22,
      );
    } else {
      buttonContent = Text(
        value,
        style: TextStyle(
          color: textColor,
          fontSize: type == _ButtonType.equals ? 24 : 20,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => type == _ButtonType.hide ? onHide() : onInput(value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: type == _ButtonType.equals
                ? [
                    BoxShadow(
                      color: appTheme.accent.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(child: buttonContent),
        ),
      ),
    );
  }
}

enum _ButtonType {
  number,
  operation,
  function,
  equals,
  hide,
}
