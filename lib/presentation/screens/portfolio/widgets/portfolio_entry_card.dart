import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/currency.dart';
import '../../../widgets/currency_icon.dart';
import '../portfolio_controller.dart';

/// Card widget displaying a portfolio entry with currency, amount, and converted value
class PortfolioEntryCard extends StatefulWidget {
  final PortfolioEntry entry;
  final Currency? baseCurrency;
  final double convertedAmount;
  final AppTheme appTheme;
  final String Function(double) formatAmount;
  final Function(double) onAmountChanged;
  final VoidCallback onRemove;

  const PortfolioEntryCard({
    super.key,
    required this.entry,
    required this.baseCurrency,
    required this.convertedAmount,
    required this.appTheme,
    required this.formatAmount,
    required this.onAmountChanged,
    required this.onRemove,
  });

  @override
  State<PortfolioEntryCard> createState() => _PortfolioEntryCardState();
}

class _PortfolioEntryCardState extends State<PortfolioEntryCard>
    with SingleTickerProviderStateMixin {
  bool _isEditing = false;
  late TextEditingController _amountController;
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.entry.amount.toString());
    _focusNode.addListener(_onFocusChange);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant PortfolioEntryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && widget.entry.amount != oldWidget.entry.amount) {
      _amountController.text = widget.entry.amount.toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      _saveAmount();
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
    _focusNode.requestFocus();
    _amountController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _amountController.text.length,
    );
  }

  void _saveAmount() {
    setState(() {
      _isEditing = false;
    });

    final text = _amountController.text.trim().replaceAll(',', '.');
    if (text.isEmpty) {
      _amountController.text = widget.entry.amount.toString();
      return;
    }

    final newAmount = double.tryParse(text);
    if (newAmount != null && newAmount > 0) {
      widget.onAmountChanged(newAmount);
    } else {
      _amountController.text = widget.entry.amount.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: Dismissible(
        key: Key('portfolio_entry_${widget.entry.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) => widget.onRemove(),
        background: _buildDismissBackground(),
        child: GestureDetector(
          onTapDown: (_) => _animationController.forward(),
          onTapUp: (_) {
            _animationController.reverse();
            _startEditing();
          },
          onTapCancel: () => _animationController.reverse(),
          child: _buildCardContent(),
        ),
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade700],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.delete_rounded, color: Colors.white, size: 22),
        ],
      ),
    );
  }

  Widget _buildCardContent() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.appTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: _isEditing
            ? Border.all(color: widget.appTheme.primary, width: 2)
            : Border.all(color: widget.appTheme.surface, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildCurrencyInfo(),
          const SizedBox(width: 12),
          Expanded(child: _buildAmountSection()),
        ],
      ),
    );
  }

  Widget _buildCurrencyInfo() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.appTheme.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: CurrencyIcon(currency: widget.entry.currency, size: 32),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.entry.currency.symbol,
              style: TextStyle(
                color: widget.appTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: 80,
              child: Text(
                widget.entry.currency.name,
                style: TextStyle(
                  color: widget.appTheme.textTertiary,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Editable amount
        _isEditing ? _buildEditableAmount() : _buildDisplayAmount(),
        const SizedBox(height: 4),
        // Converted amount
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.appTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '≈ ${widget.formatAmount(widget.convertedAmount)} ${widget.baseCurrency?.symbol ?? ''}',
            style: TextStyle(
              color: widget.appTheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableAmount() {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.appTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _amountController,
        focusNode: _focusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
        ],
        textAlign: TextAlign.right,
        style: TextStyle(
          color: widget.appTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        onSubmitted: (_) => _saveAmount(),
      ),
    );
  }

  Widget _buildDisplayAmount() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.formatAmount(widget.entry.amount),
          style: TextStyle(
            color: widget.appTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          widget.entry.currency.symbol,
          style: TextStyle(
            color: widget.appTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.edit_rounded,
          color: widget.appTheme.textTertiary,
          size: 16,
        ),
      ],
    );
  }
}
