import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
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

class _InputSectionState extends State<InputSection> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: DesignTokens.animShort,
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
    final isTablet = DesignTokens.isTablet(context);
    final horizontalPadding = DesignTokens.getScreenPaddingH(context);
    final valueFontSize = isTablet ? DesignTokens.textDisplayL : DesignTokens.textDisplay;
    final labelFontSize = isTablet ? DesignTokens.text : DesignTokens.textBody;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              margin: EdgeInsets.symmetric(
                  horizontal: horizontalPadding, vertical: DesignTokens.spaceXS),
              padding: EdgeInsets.all(isTablet ? DesignTokens.space : DesignTokens.spaceM),
              decoration: BoxDecoration(
                color: widget.appTheme.surface,
                borderRadius: BorderRadius.circular(DesignTokens.radiusXXL),
                border: Border.all(
                  color: widget.appTheme.primary,
                  width: DesignTokens.border,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.appTheme.primary.withOpacity(DesignTokens.opacityLight),
                    blurRadius: DesignTokens.shadowBlurL,
                    offset: Offset(0, DesignTokens.shadowOffsetM),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main display value with currency badge on right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          // Remove AnimatedSwitcher - direct text for instant digit updates
                          child: Text(
                            widget.displayValue,
                            style: TextStyle(
                              color: widget.appTheme.textPrimary,
                              fontSize: valueFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildCurrencyBadge(isTablet),
                    ],
                  ),
                  // Show expression hint when there's an active calculation
                  AnimatedSize(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topLeft,
                    child: widget.calculatorExpression.isNotEmpty &&
                            widget.calculatorExpression != widget.displayValue
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.calculatorExpression,
                              style: TextStyle(
                                color: widget.appTheme.textTertiary,
                                fontSize: labelFontSize - 2,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 10,
        vertical: isTablet ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: widget.appTheme.background,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CurrencyIcon(currency: widget.selectedCurrency, size: isTablet ? 24 : 20),
          const SizedBox(width: 6),
          Text(
            widget.selectedCurrency?.symbol ?? '',
            style: TextStyle(
              color: widget.appTheme.textPrimary,
              fontSize: isTablet ? DesignTokens.text : DesignTokens.textBody,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
