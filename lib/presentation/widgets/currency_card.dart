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

class _CurrencyCardState extends State<CurrencyCard> with SingleTickerProviderStateMixin {
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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.appTheme.error.withOpacity(0.85),
              widget.appTheme.error,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: Icon(Icons.delete_outline_rounded, color: widget.appTheme.textLight, size: 24),
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
            final isTablet = DesignTokens.isTablet(context);
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: EdgeInsets.only(bottom: DesignTokens.cardMarginBottom),
                padding:
                    EdgeInsets.all(isTablet ? DesignTokens.space : DesignTokens.buttonPaddingV),
                decoration: BoxDecoration(
                  color: widget.appTheme.surface,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                  boxShadow: DesignTokens.cardShadow(Colors.black),
                ),
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: widget.index,
                      child: Padding(
                        padding: EdgeInsets.all(DesignTokens.spaceXS),
                        child: Icon(
                          Icons.drag_indicator,
                          color: widget.appTheme.primaryLight,
                          size: DesignTokens.icon,
                        ),
                      ),
                    ),
                    SizedBox(width: DesignTokens.spaceS),
                    CurrencyIcon(
                        currency: widget.currency,
                        size: isTablet ? DesignTokens.currencyIconL : DesignTokens.currencyIcon),
                    SizedBox(width: DesignTokens.spaceM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.currency.symbol,
                            style: TextStyle(
                              color: widget.appTheme.textPrimary,
                              fontSize: isTablet ? DesignTokens.textL : DesignTokens.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            widget.currency.name,
                            style: TextStyle(
                              color: widget.appTheme.textTertiary,
                              fontSize: isTablet ? DesignTokens.textBody : DesignTokens.textBodyS,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.formatAmount(widget.convertedAmount),
                          style: TextStyle(
                            color: widget.appTheme.textPrimary,
                            fontSize: isTablet ? DesignTokens.textTitle : DesignTokens.textL,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '1 ${widget.selectedCurrency.symbol} = ${widget.formatAmount(widget.exchangeRate)} ${widget.currency.symbol}',
                          style: TextStyle(
                            color: widget.appTheme.textTertiary,
                            fontSize: isTablet ? DesignTokens.textCaption : DesignTokens.textS,
                          ),
                        ),
                        // 24h change indicator
                        if (widget.currency.changePercent24h != 0.0)
                          Padding(
                            padding: EdgeInsets.only(top: DesignTokens.spaceXS / 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.currency.changePercent24h >= 0
                                      ? Icons.arrow_drop_up
                                      : Icons.arrow_drop_down,
                                  color: widget.currency.changePercent24h >= 0
                                      ? widget.appTheme.success
                                      : widget.appTheme.error,
                                  size: DesignTokens.iconS,
                                ),
                                Text(
                                  '${widget.currency.changePercent24h >= 0 ? '+' : ''}${widget.currency.changePercent24h.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: widget.currency.changePercent24h >= 0
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
