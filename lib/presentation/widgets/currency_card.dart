import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
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
  bool _isPressed = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
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
            colors: [Colors.red.shade600, Colors.red.shade800],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 24),
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isPressed
                      ? widget.appTheme.surface.withOpacity(0.8)
                      : widget.appTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isPressed
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: widget.index,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.drag_indicator,
                          color: widget.appTheme.primaryLight,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CurrencyIcon(currency: widget.currency),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.currency.symbol,
                            style: TextStyle(
                              color: widget.appTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            widget.currency.name,
                            style: TextStyle(
                              color: widget.appTheme.textTertiary,
                              fontSize: 13,
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '1 ${widget.selectedCurrency.symbol} = ${widget.formatAmount(widget.exchangeRate)} ${widget.currency.symbol}',
                          style: TextStyle(
                            color: widget.appTheme.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                        // 24h change indicator
                        if (widget.currency.changePercent24h != 0.0)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.currency.changePercent24h >= 0
                                      ? Icons.arrow_drop_up
                                      : Icons.arrow_drop_down,
                                  color: widget.currency.changePercent24h >= 0
                                      ? Colors.green
                                      : Colors.red,
                                  size: 16,
                                ),
                                Text(
                                  '${widget.currency.changePercent24h >= 0 ? '+' : ''}${widget.currency.changePercent24h.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: widget.currency.changePercent24h >= 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 10,
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
