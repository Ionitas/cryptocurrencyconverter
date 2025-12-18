import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Calculator keypad widget for inputting amounts
class CalculatorPad extends StatefulWidget {
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
  State<CalculatorPad> createState() => _CalculatorPadState();
}

class _CalculatorPadState extends State<CalculatorPad>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy > 0) {
      setState(() {
        _dragOffset += details.delta.dy;
      });
    } else if (_dragOffset > 0) {
      setState(() {
        _dragOffset =
            (_dragOffset + details.delta.dy).clamp(0, double.infinity);
      });
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragOffset > 80 || velocity > 500) {
      _animationController.forward().then((_) {
        widget.onHide();
      });
    } else {
      setState(() {
        _dragOffset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final isTablet = mediaQuery.size.shortestSide >= 600;
    final buttonPadding = isTablet ? 20.0 : 16.0;
    final buttonSpacing = isTablet ? 12.0 : 8.0;
    final fontSize = isTablet ? 24.0 : 20.0;
    final equalsFontSize = isTablet ? 28.0 : 24.0;

    return SlideTransition(
      position: _slideAnimation,
      child: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: GestureDetector(
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          child: Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: bottomPadding > 0 ? bottomPadding : 16,
            ),
            decoration: BoxDecoration(
              color: widget.appTheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: widget.appTheme.primaryLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Calculator buttons
                _buildButtonRow(
                  ['C', '⌫', '%', '÷'],
                  [
                    _ButtonType.function,
                    _ButtonType.function,
                    _ButtonType.function,
                    _ButtonType.operation
                  ],
                  buttonPadding,
                  fontSize,
                  equalsFontSize,
                ),
                SizedBox(height: buttonSpacing),
                _buildButtonRow(
                  ['7', '8', '9', '×'],
                  [
                    _ButtonType.number,
                    _ButtonType.number,
                    _ButtonType.number,
                    _ButtonType.operation
                  ],
                  buttonPadding,
                  fontSize,
                  equalsFontSize,
                ),
                SizedBox(height: buttonSpacing),
                _buildButtonRow(
                  ['4', '5', '6', '-'],
                  [
                    _ButtonType.number,
                    _ButtonType.number,
                    _ButtonType.number,
                    _ButtonType.operation
                  ],
                  buttonPadding,
                  fontSize,
                  equalsFontSize,
                ),
                SizedBox(height: buttonSpacing),
                _buildButtonRow(
                  ['1', '2', '3', '+'],
                  [
                    _ButtonType.number,
                    _ButtonType.number,
                    _ButtonType.number,
                    _ButtonType.operation
                  ],
                  buttonPadding,
                  fontSize,
                  equalsFontSize,
                ),
                SizedBox(height: buttonSpacing),
                _buildButtonRow(
                  ['hide', '0', '.', '='],
                  [
                    _ButtonType.hide,
                    _ButtonType.number,
                    _ButtonType.number,
                    _ButtonType.equals
                  ],
                  buttonPadding,
                  fontSize,
                  equalsFontSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonRow(
    List<String> values,
    List<_ButtonType> types,
    double buttonPadding,
    double fontSize,
    double equalsFontSize,
  ) {
    return Row(
      children: List.generate(values.length, (index) {
        return _buildCalcButton(
          values[index],
          types[index],
          buttonPadding,
          fontSize,
          equalsFontSize,
        );
      }),
    );
  }

  Widget _buildCalcButton(
    String value,
    _ButtonType type,
    double buttonPadding,
    double fontSize,
    double equalsFontSize,
  ) {
    Color backgroundColor;
    Color textColor = widget.appTheme.textPrimary;

    switch (type) {
      case _ButtonType.operation:
        backgroundColor = widget.appTheme.primary;
      case _ButtonType.function:
        backgroundColor = widget.appTheme.surfaceLight;
        textColor = widget.appTheme.textLight;
      case _ButtonType.equals:
        backgroundColor = widget.appTheme.accent;
      case _ButtonType.hide:
        backgroundColor = widget.appTheme.surfaceLight;
      case _ButtonType.number:
        backgroundColor = widget.appTheme.background;
    }

    Widget buttonContent;
    if (type == _ButtonType.hide) {
      buttonContent = Icon(
        Icons.keyboard_hide_rounded,
        color: widget.appTheme.textLight,
        size: 22,
      );
    } else {
      buttonContent = Text(
        value,
        style: TextStyle(
          color: textColor,
          fontSize: type == _ButtonType.equals ? equalsFontSize : fontSize,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Expanded(
      child: GestureDetector(
        onTap: () =>
            type == _ButtonType.hide ? widget.onHide() : widget.onInput(value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: EdgeInsets.symmetric(vertical: buttonPadding),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: type == _ButtonType.equals
                ? [
                    BoxShadow(
                      color: widget.appTheme.accent.withOpacity(0.3),
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
