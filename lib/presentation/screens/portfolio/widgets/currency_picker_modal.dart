import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/currency.dart';
import '../../../widgets/currency_icon.dart';

/// Picker mode determines the title and action button text
enum CurrencyPickerMode {
  /// For adding a new currency to the list
  add,

  /// For changing/selecting a base currency
  change,
}

/// A reusable currency picker modal
class CurrencyPickerModal extends StatefulWidget {
  final List<Currency> currencies;
  final Function(Currency) onSelect;
  final AppTheme appTheme;
  final CurrencyPickerMode mode;
  final String? customTitle;

  const CurrencyPickerModal({
    super.key,
    required this.currencies,
    required this.onSelect,
    required this.appTheme,
    this.mode = CurrencyPickerMode.add,
    this.customTitle,
  });

  /// Shows the currency picker modal
  static void show({
    required BuildContext context,
    required List<Currency> currencies,
    required Function(Currency) onSelect,
    required AppTheme appTheme,
    CurrencyPickerMode mode = CurrencyPickerMode.add,
    String? customTitle,
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
            child: CurrencyPickerModal(
              currencies: currencies,
              onSelect: onSelect,
              appTheme: appTheme,
              mode: mode,
              customTitle: customTitle,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<CurrencyPickerModal> createState() => _CurrencyPickerModalState();
}

class _CurrencyPickerModalState extends State<CurrencyPickerModal> {
  final TextEditingController _searchController = TextEditingController();
  late List<Currency> _filteredCurrencies;

  @override
  void initState() {
    super.initState();
    _filteredCurrencies = widget.currencies;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.customTitle != null) return widget.customTitle!;
    switch (widget.mode) {
      case CurrencyPickerMode.add:
        return 'Add Currency';
      case CurrencyPickerMode.change:
        return 'Change Currency';
    }
  }

  void _filterCurrencies(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCurrencies = widget.currencies;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredCurrencies = widget.currencies.where((c) {
          return c.name.toLowerCase().contains(lowerQuery) ||
              c.symbol.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  void _selectCurrency(Currency currency) {
    widget.onSelect(currency);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            _buildDragHandle(),
            _buildHeader(),
            _buildSearchField(),
            Expanded(child: _buildCurrencyList(scrollController)),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _title,
            style: TextStyle(
              color: widget.appTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
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
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 56,
                color: widget.appTheme.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'No currencies found',
                style: TextStyle(
                  color: widget.appTheme.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Try a different search term',
                style: TextStyle(
                  color: widget.appTheme.textTertiary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredCurrencies.length,
      itemBuilder: (context, index) {
        final currency = _filteredCurrencies[index];
        return _CurrencyListItem(
          currency: currency,
          appTheme: widget.appTheme,
          onTap: () => _selectCurrency(currency),
        );
      },
    );
  }
}

class _CurrencyListItem extends StatelessWidget {
  final Currency currency;
  final AppTheme appTheme;
  final VoidCallback onTap;

  const _CurrencyListItem({
    required this.currency,
    required this.appTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: appTheme.background,
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
                      color: appTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currency.name,
                    style: TextStyle(
                      color: appTheme.textTertiary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: appTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: appTheme.primary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
