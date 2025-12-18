import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// Calculator keypad widget with smooth slide animation and Liquid Glass effect
class CalculatorPad extends StatefulWidget {
  final AppTheme appTheme;
  final Function(String) onInput;
  final VoidCallback onHide;
  final double slideProgress; // 0.0 = hidden, 1.0 = fully visible

  const CalculatorPad({
    super.key,
    required this.appTheme,
    required this.onInput,
    required this.onHide,
    this.slideProgress = 1.0,
  });

  @override
  State<CalculatorPad> createState() => _CalculatorPadState();
}

class _CalculatorPadState extends State<CalculatorPad> {
  // Cache button data for performance
  static const List<List<String>> _buttonValues = [
    ['C', '⌫', '%', '÷'],
    ['7', '8', '9', '×'],
    ['4', '5', '6', '-'],
    ['1', '2', '3', '+'],
    ['hide', '0', '.', '='],
  ];

  static const List<List<_ButtonType>> _buttonTypes = [
    [
      _ButtonType.function,
      _ButtonType.function,
      _ButtonType.function,
      _ButtonType.operation
    ],
    [
      _ButtonType.number,
      _ButtonType.number,
      _ButtonType.number,
      _ButtonType.operation
    ],
    [
      _ButtonType.number,
      _ButtonType.number,
      _ButtonType.number,
      _ButtonType.operation
    ],
    [
      _ButtonType.number,
      _ButtonType.number,
      _ButtonType.number,
      _ButtonType.operation
    ],
    [
      _ButtonType.hide,
      _ButtonType.number,
      _ButtonType.number,
      _ButtonType.equals
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final isTablet = mediaQuery.size.shortestSide >= 600;
    final buttonPadding = isTablet ? 20.0 : 16.0;
    final buttonSpacing = isTablet ? 12.0 : 8.0;
    final fontSize = isTablet ? 24.0 : 20.0;
    final equalsFontSize = isTablet ? 28.0 : 24.0;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: bottomPadding > 0 ? bottomPadding : 16,
          ),
          decoration: BoxDecoration(
            color: widget.appTheme.surface.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, -8),
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
                  color: widget.appTheme.primaryLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Calculator buttons - using RepaintBoundary for performance
              RepaintBoundary(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (rowIndex) {
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: rowIndex < 4 ? buttonSpacing : 0),
                      child: _CalculatorRow(
                        values: _buttonValues[rowIndex],
                        types: _buttonTypes[rowIndex],
                        appTheme: widget.appTheme,
                        buttonPadding: buttonPadding,
                        fontSize: fontSize,
                        equalsFontSize: equalsFontSize,
                        onInput: widget.onInput,
                        onHide: widget.onHide,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Optimized calculator button row - separated for better rebuild performance
class _CalculatorRow extends StatelessWidget {
  final List<String> values;
  final List<_ButtonType> types;
  final AppTheme appTheme;
  final double buttonPadding;
  final double fontSize;
  final double equalsFontSize;
  final Function(String) onInput;
  final VoidCallback onHide;

  const _CalculatorRow({
    required this.values,
    required this.types,
    required this.appTheme,
    required this.buttonPadding,
    required this.fontSize,
    required this.equalsFontSize,
    required this.onInput,
    required this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(values.length, (index) {
        return _CalculatorButton(
          value: values[index],
          type: types[index],
          appTheme: appTheme,
          buttonPadding: buttonPadding,
          fontSize: fontSize,
          equalsFontSize: equalsFontSize,
          onInput: onInput,
          onHide: onHide,
        );
      }),
    );
  }
}

/// Individual calculator button with haptic feedback
class _CalculatorButton extends StatelessWidget {
  final String value;
  final _ButtonType type;
  final AppTheme appTheme;
  final double buttonPadding;
  final double fontSize;
  final double equalsFontSize;
  final Function(String) onInput;
  final VoidCallback onHide;

  const _CalculatorButton({
    required this.value,
    required this.type,
    required this.appTheme,
    required this.buttonPadding,
    required this.fontSize,
    required this.equalsFontSize,
    required this.onInput,
    required this.onHide,
  });

  Color get _backgroundColor {
    switch (type) {
      case _ButtonType.operation:
        return appTheme.primary;
      case _ButtonType.function:
        return appTheme.surfaceLight;
      case _ButtonType.equals:
        return appTheme.accent;
      case _ButtonType.hide:
        return appTheme.surfaceLight;
      case _ButtonType.number:
        return appTheme.background.withOpacity(0.8);
    }
  }

  Color get _textColor {
    switch (type) {
      case _ButtonType.function:
      case _ButtonType.hide:
        return appTheme.textLight;
      default:
        return appTheme.textPrimary;
    }
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    if (type == _ButtonType.hide) {
      onHide();
    } else {
      onInput(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: EdgeInsets.symmetric(vertical: buttonPadding),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: type == _ButtonType.equals
                ? [
                    BoxShadow(
                      color: appTheme.accent.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(child: _buildContent()),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (type == _ButtonType.hide) {
      return Icon(
        Icons.keyboard_hide_rounded,
        color: appTheme.textLight,
        size: 22,
      );
    }
    return Text(
      value,
      style: TextStyle(
        color: _textColor,
        fontSize: type == _ButtonType.equals ? equalsFontSize : fontSize,
        fontWeight: FontWeight.w600,
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
