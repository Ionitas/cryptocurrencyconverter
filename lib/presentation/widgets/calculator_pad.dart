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
    final buttonPadding = isTablet ? 16.0 : 12.0;
    final buttonSpacing = isTablet ? 10.0 : 6.0;
    final fontSize = isTablet ? 22.0 : 18.0;
    final equalsFontSize = isTablet ? 26.0 : 22.0;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 10,
            bottom: bottomPadding > 0 ? bottomPadding : 12,
          ),
          decoration: BoxDecoration(
            color: widget.appTheme.surface.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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

/// Individual calculator button with haptic feedback and press animation
class _CalculatorButton extends StatefulWidget {
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

  @override
  State<_CalculatorButton> createState() => _CalculatorButtonState();
}

class _CalculatorButtonState extends State<_CalculatorButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    switch (widget.type) {
      case _ButtonType.operation:
        return widget.appTheme.primary;
      case _ButtonType.function:
        return widget.appTheme.surfaceLight;
      case _ButtonType.equals:
        return widget.appTheme.accent;
      case _ButtonType.hide:
        return widget.appTheme.surfaceLight;
      case _ButtonType.number:
        return widget.appTheme.background.withOpacity(0.8);
    }
  }

  Color get _pressedColor {
    switch (widget.type) {
      case _ButtonType.operation:
        return widget.appTheme.primary.withOpacity(0.8);
      case _ButtonType.function:
        return widget.appTheme.surfaceLight.withOpacity(0.7);
      case _ButtonType.equals:
        return widget.appTheme.accent.withOpacity(0.8);
      case _ButtonType.hide:
        return widget.appTheme.surfaceLight.withOpacity(0.7);
      case _ButtonType.number:
        return widget.appTheme.surface;
    }
  }

  Color get _textColor {
    switch (widget.type) {
      case _ButtonType.function:
      case _ButtonType.hide:
        return widget.appTheme.textLight;
      default:
        return widget.appTheme.textPrimary;
    }
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    HapticFeedback.lightImpact();
    if (widget.type == _ButtonType.hide) {
      widget.onHide();
    } else {
      widget.onInput(widget.value);
    }
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: EdgeInsets.symmetric(vertical: widget.buttonPadding),
                decoration: BoxDecoration(
                  color: _isPressed ? _pressedColor : _backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(_isPressed ? 0.12 : 0.08),
                    width: 1,
                  ),
                  boxShadow: widget.type == _ButtonType.equals && !_isPressed
                      ? [
                          BoxShadow(
                            color: widget.appTheme.accent.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(child: _buildContent()),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.type == _ButtonType.hide) {
      return Icon(
        Icons.keyboard_hide_rounded,
        color: widget.appTheme.textLight,
        size: 22,
      );
    }
    return Text(
      widget.value,
      style: TextStyle(
        color: _textColor,
        fontSize: widget.type == _ButtonType.equals
            ? widget.equalsFontSize
            : widget.fontSize,
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
