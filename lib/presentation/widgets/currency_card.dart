import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../domain/models/currency.dart';
import 'currency_icon.dart';

/// Displays a currency conversion card that can be reordered and dismissed
class CurrencyCard extends StatefulWidget {
  final Currency currency;
  final Currency selectedCurrency;
  final int index;
  final double convertedAmount;
  final double exchangeRate;
  final AppTheme appTheme;
  final VoidCallback onTap;
  final VoidCallback onDismissed;
  final VoidCallback onUndo;
  final String Function(double) formatAmount;

  const CurrencyCard({
    super.key,
    required this.currency,
    required this.selectedCurrency,
    required this.index,
    required this.convertedAmount,
    required this.exchangeRate,
    required this.appTheme,
    required this.onTap,
    required this.onDismissed,
    required this.onUndo,
    required this.formatAmount,
  });

  @override
  State<CurrencyCard> createState() => _CurrencyCardState();
}

class _CurrencyCardState extends State<CurrencyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = DesignTokens.isTablet(context);
    final isPositiveChange = widget.currency.changePercent24h >= 0;

    return Dismissible(
      key: Key('dismissible_${widget.currency.symbol}'),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.3},
      movementDuration: const Duration(milliseconds: 200),
      onDismissed: (direction) {
        HapticFeedback.mediumImpact();
        widget.onDismissed();
      },
      background: Container(
        margin: EdgeInsets.only(bottom: DesignTokens.cardMarginBottom + 4),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.appTheme.error.withValues(alpha: 0.7),
              widget.appTheme.error,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
        ),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Remove',
              style: TextStyle(
                color: widget.appTheme.textLight,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded,
                color: widget.appTheme.textLight, size: 22),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin:
                    EdgeInsets.only(bottom: DesignTokens.cardMarginBottom + 2),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? DesignTokens.spaceS : 10,
                  vertical: isTablet ? DesignTokens.spaceS : 10,
                ),
                decoration: BoxDecoration(
                  color: widget.appTheme.surface,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
                  border: Border.all(
                    color: widget.appTheme.surfaceLight.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Drag handle - compact styling
                    ReorderableDragStartListener(
                      index: widget.index,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          color: widget.appTheme.textTertiary
                              .withValues(alpha: 0.6),
                          size: 18,
                        ),
                      ),
                    ),
                    SizedBox(width: DesignTokens.spaceS),
                    // Currency icon with subtle background
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: widget.currency.isCrypto
                            ? widget.appTheme.cryptoBackground
                            : widget.appTheme.fiatBackground,
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusM),
                      ),
                      child: CurrencyIcon(
                        currency: widget.currency,
                        size: isTablet
                            ? DesignTokens.currencyIconL
                            : DesignTokens.currencyIcon,
                      ),
                    ),
                    SizedBox(width: DesignTokens.spaceS),
                    // Currency info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.currency.symbol,
                                style: TextStyle(
                                  color: widget.appTheme.textPrimary,
                                  fontSize: isTablet
                                      ? DesignTokens.textL
                                      : DesignTokens.text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (widget.currency.changePercent24h != 0.0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isPositiveChange
                                        ? widget.appTheme.success
                                            .withValues(alpha: 0.15)
                                        : widget.appTheme.error
                                            .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPositiveChange
                                            ? Icons.trending_up_rounded
                                            : Icons.trending_down_rounded,
                                        color: isPositiveChange
                                            ? widget.appTheme.success
                                            : widget.appTheme.error,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${isPositiveChange ? '+' : ''}${widget.currency.changePercent24h.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          color: isPositiveChange
                                              ? widget.appTheme.success
                                              : widget.appTheme.error,
                                          fontSize: DesignTokens.textXS,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.currency.name,
                            style: TextStyle(
                              color: widget.appTheme.textTertiary,
                              fontSize: isTablet
                                  ? DesignTokens.textBody
                                  : DesignTokens.textBodyS,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Converted amount column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.formatAmount(widget.convertedAmount),
                          style: TextStyle(
                            color: widget.appTheme.textPrimary,
                            fontSize: isTablet
                                ? DesignTokens.textTitle
                                : DesignTokens.textL,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '1 ${widget.selectedCurrency.symbol} = ${widget.formatAmount(widget.exchangeRate)}',
                          style: TextStyle(
                            color: widget.appTheme.textTertiary,
                            fontSize: isTablet
                                ? DesignTokens.textCaption
                                : DesignTokens.textS,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 2),
                    // Tap indicator
                    Icon(
                      Icons.swap_horiz_rounded,
                      color: widget.appTheme.primary.withValues(alpha: 0.5),
                      size: 18,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
