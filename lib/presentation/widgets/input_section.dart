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

class _InputSectionState extends State<InputSection>
    with SingleTickerProviderStateMixin {
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
    _pulseController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _pulseController.reverse();
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  void _onTapCancel() {
    _pulseController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = DesignTokens.isTablet(context);
    final horizontalPadding = DesignTokens.getScreenPaddingH(context);
    final valueFontSize =
        isTablet ? DesignTokens.textDisplayL : DesignTokens.textDisplay;
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
                  horizontal: horizontalPadding, vertical: DesignTokens.spaceS),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? DesignTokens.spaceL : DesignTokens.space,
                vertical: isTablet ? DesignTokens.spaceL : DesignTokens.spaceM,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.appTheme.surface,
                    widget.appTheme.surface.withValues(alpha: 0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(DesignTokens.radiusXXL),
                border: Border.all(
                  color: widget.appTheme.primary.withValues(alpha: 0.6),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.appTheme.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tap hint label
                  Row(
                    children: [
                      Icon(
                        Icons.calculate_rounded,
                        color: widget.appTheme.primary.withValues(alpha: 0.7),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to edit',
                        style: TextStyle(
                          color: widget.appTheme.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Main display value with currency badge on right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.displayValue,
                            style: TextStyle(
                              color: widget.appTheme.textPrimary,
                              fontSize: valueFontSize,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
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
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: widget.appTheme.surfaceLight
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.calculatorExpression,
                                style: TextStyle(
                                  color: widget.appTheme.textSecondary,
                                  fontSize: labelFontSize - 2,
                                  fontFamily: 'monospace',
                                ),
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
    final isCrypto = widget.selectedCurrency?.isCrypto ?? false;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14 : 12,
        vertical: isTablet ? 10 : 8,
      ),
      decoration: BoxDecoration(
        color: isCrypto
            ? widget.appTheme.cryptoBackground
            : widget.appTheme.fiatBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: isCrypto
              ? widget.appTheme.accent.withValues(alpha: 0.3)
              : widget.appTheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CurrencyIcon(
              currency: widget.selectedCurrency, size: isTablet ? 26 : 22),
          const SizedBox(width: 8),
          Text(
            widget.selectedCurrency?.symbol ?? '',
            style: TextStyle(
              color: widget.appTheme.textPrimary,
              fontSize: isTablet ? DesignTokens.text : DesignTokens.textBody,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
