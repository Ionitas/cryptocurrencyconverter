import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/di/injection.dart';
import '../../core/services/analytics/analytics_manager.dart';
import '../../domain/models/currency.dart';
import 'currency_icon.dart';

/// Modal bottom sheet for adding currencies with Liquid Glass search at bottom
class AddCurrencyModal extends StatefulWidget {
  final List<Currency> availableCurrencies;
  final Function(Currency) onAdd;

  const AddCurrencyModal({
    super.key,
    required this.availableCurrencies,
    required this.onAdd,
  });

  /// Shows the add currency modal with Liquid Glass effect
  static void show({
    required BuildContext context,
    required List<Currency> availableCurrencies,
    required Function(Currency) onAdd,
  }) {
    final appTheme = getIt<AppTheme>();
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
              color: appTheme.surface.withValues(alpha: 0.85),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: AddCurrencyModal(
              availableCurrencies: availableCurrencies,
              onAdd: onAdd,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<AddCurrencyModal> createState() => _AddCurrencyModalState();
}

class _AddCurrencyModalState extends State<AddCurrencyModal> {
  final AppTheme _appTheme = getIt<AppTheme>();
  final AnalyticsManager _analytics = getIt<AnalyticsManager>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  late List<Currency> _filteredCurrencies;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _filteredCurrencies = widget.availableCurrencies;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterCurrencies(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCurrencies = widget.availableCurrencies;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredCurrencies = widget.availableCurrencies.where((c) {
          // Case-insensitive search across code, name, and symbol
          return c.code.toLowerCase().contains(lowerQuery) ||
              c.name.toLowerCase().contains(lowerQuery) ||
              c.symbol.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });

    // Debounced search analytics (log after 800ms of no typing)
    _searchDebounce?.cancel();
    if (query.length >= 2) {
      _searchDebounce = Timer(const Duration(milliseconds: 800), () {
        _analytics.logCurrencySearch(
          query: query,
          resultCount: _filteredCurrencies.length,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    // Keep modal content above keyboard without breaking drag.
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
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: _appTheme.primaryLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Currency',
                    style: TextStyle(
                      color: _appTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_filteredCurrencies.length} available',
                    style: TextStyle(
                      color: _appTheme.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Currency list
            Expanded(
              child: _filteredCurrencies.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'All currencies added'
                              : 'No currencies found for "$_searchQuery"',
                          style: TextStyle(
                            color: _appTheme.textTertiary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.only(
                        bottom: (bottomPadding > 0 ? bottomPadding : 16) + 72,
                      ),
                      itemCount: _filteredCurrencies.length,
                      itemBuilder: (context, index) {
                        final currency = _filteredCurrencies[index];
                        return _CurrencyListItem(
                          currency: currency,
                          appTheme: _appTheme,
                          onTap: () {
                            widget.onAdd(currency);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
            // Liquid Glass Search Bar at bottom
            _buildLiquidGlassSearchBar(bottomPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildLiquidGlassSearchBar(double bottomPadding) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: bottomPadding > 0 ? bottomPadding : 16,
          ),
          decoration: BoxDecoration(
            color: _appTheme.surface.withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _appTheme.background.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _appTheme.primary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyle(color: _appTheme.textPrimary, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search currencies...',
                hintStyle: TextStyle(color: _appTheme.textTertiary),
                border: InputBorder.none,
                icon: Icon(
                  Icons.search_rounded,
                  color: _appTheme.primary,
                  size: 22,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _filterCurrencies('');
                        },
                        child: Icon(
                          Icons.close_rounded,
                          color: _appTheme.textTertiary,
                          size: 20,
                        ),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: _filterCurrencies,
            ),
          ),
        ),
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    appTheme.background.withValues(alpha: 0.5),
                    appTheme.background.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: currency.isCrypto
                      ? appTheme.accent.withValues(alpha: 0.2)
                      : appTheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Currency type indicator with icon
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: currency.isCrypto
                          ? appTheme.cryptoBackground
                          : appTheme.fiatBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CurrencyIcon(currency: currency, size: 38),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              currency.symbol,
                              style: TextStyle(
                                color: appTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: currency.isCrypto
                                    ? appTheme.accent.withValues(alpha: 0.15)
                                    : appTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                currency.isCrypto ? 'Crypto' : 'Fiat',
                                style: TextStyle(
                                  color: currency.isCrypto
                                      ? appTheme.accent
                                      : appTheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currency.name,
                          style: TextStyle(
                            color: appTheme.textTertiary,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          appTheme.primary,
                          appTheme.primary.withValues(alpha: 0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: appTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
