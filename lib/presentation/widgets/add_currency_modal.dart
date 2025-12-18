import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/di/injection.dart';
import '../../domain/models/currency.dart';
import 'currency_icon.dart';

/// Modal bottom sheet for adding currencies with search
class AddCurrencyModal extends StatefulWidget {
  final List<Currency> availableCurrencies;
  final Function(Currency) onAdd;

  const AddCurrencyModal({
    super.key,
    required this.availableCurrencies,
    required this.onAdd,
  });

  /// Shows the add currency modal and returns the added currency if any
  static void show({
    required BuildContext context,
    required List<Currency> availableCurrencies,
    required Function(Currency) onAdd,
  }) {
    final appTheme = getIt<AppTheme>();
    showModalBottomSheet(
      context: context,
      backgroundColor: appTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (modalContext) => AddCurrencyModal(
        availableCurrencies: availableCurrencies,
        onAdd: onAdd,
      ),
    );
  }

  @override
  State<AddCurrencyModal> createState() => _AddCurrencyModalState();
}

class _AddCurrencyModalState extends State<AddCurrencyModal> {
  final AppTheme _appTheme = getIt<AppTheme>();
  String _searchQuery = '';
  late List<Currency> _filteredCurrencies;

  @override
  void initState() {
    super.initState();
    _filteredCurrencies = widget.availableCurrencies;
  }

  void _filterCurrencies(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCurrencies = widget.availableCurrencies;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredCurrencies = widget.availableCurrencies.where((c) {
          return c.name.toLowerCase().contains(lowerQuery) ||
              c.symbol.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
                color: _appTheme.primaryLight,
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
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _appTheme.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  style: TextStyle(color: _appTheme.textPrimary, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Search currencies...',
                    hintStyle: TextStyle(color: _appTheme.textTertiary),
                    border: InputBorder.none,
                    icon: Icon(Icons.search,
                        color: _appTheme.textTertiary, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: _filterCurrencies,
                ),
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
                      itemCount: _filteredCurrencies.length,
                      itemBuilder: (context, index) {
                        final currency = _filteredCurrencies[index];
                        return _CurrencyListItem(
                          currency: currency,
                          appTheme: _appTheme,
                          onTap: () {
                            widget.onAdd(currency);
                            // Remove from filtered list
                            setState(() {
                              _filteredCurrencies = _filteredCurrencies
                                  .where((c) => c.id != currency.id)
                                  .toList();
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
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
    return ListTile(
      leading: CurrencyIcon(currency: currency),
      title: Text(
        currency.name,
        style: TextStyle(color: appTheme.textPrimary),
      ),
      subtitle: Text(
        currency.symbol,
        style: TextStyle(color: appTheme.textTertiary),
      ),
      trailing: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: appTheme.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Add',
            style: TextStyle(
              color: appTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}
