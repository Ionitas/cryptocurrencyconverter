import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/currency.dart';
import '../../../widgets/currency_icon.dart';

/// Modal for adding a currency with amount to the portfolio
class AddPortfolioEntryModal extends StatefulWidget {
  final List<Currency> allCurrencies;
  final Function(Currency, double) onAdd;
  final AppTheme appTheme;

  const AddPortfolioEntryModal({
    super.key,
    required this.allCurrencies,
    required this.onAdd,
    required this.appTheme,
  });

  /// Shows the add portfolio entry modal
  static void show({
    required BuildContext context,
    required List<Currency> allCurrencies,
    required Function(Currency, double) onAdd,
    required AppTheme appTheme,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (modalContext) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: appTheme.surface.withValues(alpha: 0.92),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: AddPortfolioEntryModal(
              allCurrencies: allCurrencies,
              onAdd: onAdd,
              appTheme: appTheme,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<AddPortfolioEntryModal> createState() => _AddPortfolioEntryModalState();
}

class _AddPortfolioEntryModalState extends State<AddPortfolioEntryModal> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();

  late List<Currency> _filteredCurrencies;
  Currency? _selectedCurrency;

  // Step: 0 = select currency, 1 = enter amount
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _filteredCurrencies = widget.allCurrencies;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _filterCurrencies(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCurrencies = widget.allCurrencies;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredCurrencies = widget.allCurrencies.where((c) {
          return c.name.toLowerCase().contains(lowerQuery) ||
              c.symbol.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  void _selectCurrency(Currency currency) {
    setState(() {
      _selectedCurrency = currency;
      _currentStep = 1;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _amountFocusNode.requestFocus();
    });
  }

  void _goBackToSelection() {
    setState(() {
      _currentStep = 0;
      _selectedCurrency = null;
      _amountController.clear();
    });
  }

  void _addEntry() {
    if (_selectedCurrency == null) return;

    final amountText = _amountController.text.trim().replaceAll(',', '.');
    if (amountText.isEmpty) {
      _showError('Please enter an amount');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    widget.onAdd(_selectedCurrency!, amount);
    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: widget.appTheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    // Keep the sheet above the keyboard while preserving drag behavior.
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            _buildDragHandle(),
            _buildHeader(),
            _buildStepIndicator(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _currentStep == 0
                    ? _buildCurrencySelection(scrollController)
                    : _buildAmountEntryContent(),
              ),
            ),
            // Add button fixed at bottom when in step 1
            if (_currentStep == 1) ...[
              Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: bottomPadding > 0 ? bottomPadding : 16,
                ),
                child: _buildAddButton(),
              ),
            ] else
              SizedBox(height: bottomPadding > 0 ? bottomPadding : 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      decoration: BoxDecoration(
        color: widget.appTheme.primaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          if (_currentStep == 1)
            GestureDetector(
              onTap: _goBackToSelection,
              child: Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: widget.appTheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: widget.appTheme.textPrimary,
                  size: 20,
                ),
              ),
            ),
          Expanded(
            child: Text(
              _currentStep == 0 ? 'Select Currency' : 'Enter Amount',
              style: TextStyle(
                color: widget.appTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_currentStep == 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.appTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_filteredCurrencies.length}',
                style: TextStyle(
                  color: widget.appTheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _buildStepDot(0, 'Currency'),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: _currentStep >= 1 ? widget.appTheme.primary : widget.appTheme.background,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          _buildStepDot(1, 'Amount'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? widget.appTheme.primary : widget.appTheme.background,
            shape: BoxShape.circle,
            border: isCurrent ? Border.all(color: widget.appTheme.primary, width: 2) : null,
          ),
          child: Center(
            child: isActive && !isCurrent
                ? Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : widget.appTheme.textTertiary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? widget.appTheme.textPrimary : widget.appTheme.textTertiary,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencySelection(ScrollController scrollController) {
    return Column(
      key: const ValueKey('currency_selection'),
      children: [
        _buildSearchField(),
        Expanded(child: _buildCurrencyList(scrollController)),
      ],
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: widget.appTheme.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: widget.appTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search currencies...',
            hintStyle: TextStyle(color: widget.appTheme.textTertiary),
            prefixIcon: Icon(Icons.search, color: widget.appTheme.textTertiary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: widget.appTheme.textTertiary, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _filterCurrencies('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: _filterCurrencies,
        ),
      ),
    );
  }

  Widget _buildCurrencyList(ScrollController scrollController) {
    if (_filteredCurrencies.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: widget.appTheme.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No currencies found',
              style: TextStyle(color: widget.appTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        // Ensure last rows are not obscured by bottom safe area.
        bottom:
            MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 16,
      ),
      itemCount: _filteredCurrencies.length,
      itemBuilder: (context, index) {
        final currency = _filteredCurrencies[index];
        return _buildCurrencyItem(currency);
      },
    );
  }

  Widget _buildCurrencyItem(Currency currency) {
    return GestureDetector(
      onTap: () => _selectCurrency(currency),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: widget.appTheme.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CurrencyIcon(currency: currency, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency.symbol,
                    style: TextStyle(
                      color: widget.appTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    currency.name,
                    style: TextStyle(color: widget.appTheme.textTertiary, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.appTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.chevron_right_rounded, color: widget.appTheme.primary, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountEntryContent() {
    return SingleChildScrollView(
      key: const ValueKey('amount_entry'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildAmountInput(),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.appTheme.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.appTheme.primary, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_rounded, color: widget.appTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Amount',
                style: TextStyle(
                  color: widget.appTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                  style: TextStyle(
                    color: widget.appTheme.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      color: widget.appTheme.textTertiary,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _addEntry(),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.appTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _selectedCurrency?.symbol ?? '',
                  style: TextStyle(
                    color: widget.appTheme.textSecondary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _addEntry,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.appTheme.primary, widget.appTheme.primary.withValues(alpha: 0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.appTheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Add to Portfolio',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
