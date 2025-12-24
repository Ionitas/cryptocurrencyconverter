import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/currency.dart';
import 'currency_icon.dart';

/// Displays the main input section showing the amount being converted
class InputSection extends StatefulWidget {
  final Currency? selectedCurrency;
  final String displayValue;
  final String calculatorExpression;
  final AppTheme appTheme;
  final VoidCallback onTap;

  const InputSection({
    super.key,
    required this.selectedCurrency,
    required this.displayValue,
    required this.calculatorExpression,
    required this.appTheme,
    required this.onTap,
  });

  @override
  State<InputSection> createState() => _InputSectionState();
}

class _InputSectionState extends State<InputSection>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _pulseController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _pulseController.reverse();
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _pulseController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.shortestSide >= 600;
    final horizontalPadding = isTablet ? 24.0 : 16.0;
    final valueFontSize = isTablet ? 52.0 : 42.0;
    final labelFontSize = isTablet ? 16.0 : 14.0;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              key: ValueKey(widget.selectedCurrency?.symbol ?? 'none'),
              margin: EdgeInsets.symmetric(
                  horizontal: horizontalPadding, vertical: 8),
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                color: widget.appTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isPressed
                      ? widget.appTheme.primary.withOpacity(0.8)
                      : widget.appTheme.primary,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.appTheme.primary
                        .withOpacity(_isPressed ? 0.15 : 0.1),
                    blurRadius: _isPressed ? 20 : 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'You convert',
                        style: TextStyle(
                          color: widget.appTheme.textSecondary,
                          fontSize: labelFontSize,
                        ),
                      ),
                      _buildCurrencyBadge(isTablet),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Main display value with smooth number transition
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            child: Text(
                              widget.displayValue,
                              key: ValueKey(widget.displayValue),
                              style: TextStyle(
                                color: widget.appTheme.textPrimary,
                                fontSize: valueFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Show expression hint when there's an active calculation
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: widget.calculatorExpression.isNotEmpty &&
                            widget.calculatorExpression != widget.displayValue
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.calculatorExpression,
                        style: TextStyle(
                          color: widget.appTheme.textTertiary,
                          fontSize: labelFontSize - 2,
                        ),
                      ),
                    ),
                    secondChild: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrencyBadge(bool isTablet) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 10,
        vertical: isTablet ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: widget.appTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CurrencyIcon(
              currency: widget.selectedCurrency, size: isTablet ? 24 : 20),
          const SizedBox(width: 6),
          Text(
            widget.selectedCurrency?.symbol ?? '',
            style: TextStyle(
              color: widget.appTheme.textPrimary,
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
