import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

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
    final bottomPadding = DesignTokens.getBottomPadding(context);
    final isTablet = DesignTokens.isTablet(context);
    final buttonPadding = isTablet ? DesignTokens.space : DesignTokens.spaceM;
    final buttonSpacing =
        isTablet ? DesignTokens.radiusS : DesignTokens.spaceS - 2;
    final fontSize = isTablet ? DesignTokens.textHeadline : DesignTokens.textL;
    final equalsFontSize = isTablet ? 26.0 : DesignTokens.textHeadline;

    return ClipRRect(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusXXL)),
      child: BackdropFilter(
        filter: ImageFilter.blur(
            sigmaX: DesignTokens.blurHeavy, sigmaY: DesignTokens.blurHeavy),
        child: Container(
          padding: EdgeInsets.only(
            left: DesignTokens.spaceM,
            right: DesignTokens.spaceM,
            top: DesignTokens.radiusS,
            bottom: bottomPadding,
          ),
          decoration: BoxDecoration(
            color: widget.appTheme.surface
                .withOpacity(DesignTokens.opacityVeryHigh),
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(DesignTokens.radiusXXL)),
            border: Border(
              top: BorderSide(
                color:
                    Colors.white.withOpacity(DesignTokens.opacityMediumLight),
                width: DesignTokens.borderThin,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(DesignTokens.shadowOpacityHeavy),
                blurRadius: DesignTokens.blurVeryHeavy,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle indicator
              Container(
                width: DesignTokens.dragHandleWidth,
                height: DesignTokens.dragHandleHeight,
                margin: EdgeInsets.only(bottom: DesignTokens.spaceM),
                decoration: BoxDecoration(
                  color: widget.appTheme.primaryLight
                      .withOpacity(DesignTokens.opacityVeryHeavy),
                  borderRadius: BorderRadius.circular(DesignTokens.spaceXS / 2),
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
        return widget.appTheme.primary.withValues(alpha: 0.9);
      case _ButtonType.function:
        return widget.appTheme.surfaceLight.withValues(alpha: 0.8);
      case _ButtonType.equals:
        return widget.appTheme.accent;
      case _ButtonType.hide:
        return widget.appTheme.surfaceLight.withValues(alpha: 0.6);
      case _ButtonType.number:
        return widget.appTheme.background.withValues(alpha: 0.85);
    }
  }

  Color get _textColor {
    switch (widget.type) {
      case _ButtonType.operation:
        return Colors.white;
      case _ButtonType.equals:
        return Colors.white;
      case _ButtonType.function:
        return widget.appTheme.textLight;
      case _ButtonType.hide:
        return widget.appTheme.textSecondary;
      default:
        return widget.appTheme.textPrimary;
    }
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    HapticFeedback.lightImpact();
    if (widget.type == _ButtonType.hide) {
      widget.onHide();
    } else {
      widget.onInput(widget.value);
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isSpecial = widget.type == _ButtonType.operation ||
        widget.type == _ButtonType.equals;

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
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                padding: EdgeInsets.symmetric(vertical: widget.buttonPadding),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSpecial
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                  boxShadow: [
                    if (widget.type == _ButtonType.equals)
                      BoxShadow(
                        color: widget.appTheme.accent.withValues(alpha: 0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    if (widget.type == _ButtonType.operation)
                      BoxShadow(
                        color: widget.appTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
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
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: widget.appTheme.background.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.keyboard_hide_rounded,
          color: widget.appTheme.textSecondary,
          size: 20,
        ),
      );
    }
    return Text(
      widget.value,
      style: TextStyle(
        color: _textColor,
        fontSize: widget.type == _ButtonType.equals
            ? widget.equalsFontSize
            : widget.fontSize,
        fontWeight: widget.type == _ButtonType.number
            ? FontWeight.w500
            : FontWeight.w700,
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
