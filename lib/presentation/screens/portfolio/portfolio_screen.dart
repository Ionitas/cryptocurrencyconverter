import 'package:flutter/material.dart';
import '../../../domain/repositories/currency_repository.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../utils/snackbar_helper.dart';
import 'portfolio_controller.dart';
import 'widgets/widgets.dart';
import 'widgets/add_portfolio_entry_modal.dart';

/// Portfolio screen for aggregating multiple currency amounts
class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  late final PortfolioController _controller;
  final AppTheme _appTheme = getIt<AppTheme>();

  @override
  void initState() {
    super.initState();
    _controller = PortfolioController(repository: getIt<CurrencyRepository>());
    _controller.addListener(_onControllerChanged);
    _appTheme.addListener(_onThemeChanged);
    _controller.loadCurrencies();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _appTheme.removeListener(_onThemeChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  void _onThemeChanged() {
    setState(() {});
  }

  void _showChangeCurrencyPicker() {
    CurrencyPickerModal.show(
      context: context,
      currencies: _controller.allCurrencies,
      onSelect: (currency) {
        _controller.setBaseCurrency(currency);
        Navigator.pop(context);
        SnackBarHelper.show(
          context: context,
          message: 'Base currency changed to ${currency.symbol}',
          appTheme: _appTheme,
          type: SnackBarType.info,
          duration: const Duration(seconds: 1),
        );
      },
      appTheme: _appTheme,
      mode: CurrencyPickerMode.change,
      customTitle: 'Select Base Currency',
    );
  }

  void _showAddEntryModal() {
    AddPortfolioEntryModal.show(
      context: context,
      allCurrencies: _controller.allCurrencies,
      onAdd: (currency, amount) {
        _controller.addEntry(currency, amount);
        SnackBarHelper.show(
          context: context,
          message: '${currency.symbol} added to portfolio',
          appTheme: _appTheme,
          type: SnackBarType.success,
          duration: const Duration(seconds: 1),
        );
      },
      appTheme: _appTheme,
    );
  }

  void _removeEntry(String id) {
    final removed = _controller.removeEntry(id);
    if (removed != null) {
      SnackBarHelper.show(
        context: context,
        message: '${removed.currency.symbol} removed',
        appTheme: _appTheme,
        type: SnackBarType.info,
        duration: const Duration(seconds: 1),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appTheme.background,
      body: SafeArea(
        child: _controller.isLoading ? _buildLoadingState() : _buildContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _appTheme.primary),
          const SizedBox(height: 16),
          Text(
            'Loading currencies...',
            style: TextStyle(
              color: _appTheme.textTertiary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.shortestSide >= 600;
    final horizontalPadding = isTablet ? 24.0 : 16.0;

    return Column(
      children: [
        // Total section with base currency
        PortfolioTotalSection(
          total: _controller.total,
          baseCurrency: _controller.baseCurrency,
          entryCount: _controller.entryCount,
          formatAmount: _controller.formatAmount,
          appTheme: _appTheme,
          onChangeCurrency: _showChangeCurrencyPicker,
        ),
        // Entries list or empty state
        Expanded(
          child: _controller.entries.isEmpty
              ? PortfolioEmptyState(
                  appTheme: _appTheme,
                  onAddCurrency: _showAddEntryModal,
                )
              : _buildEntriesList(horizontalPadding),
        ),
        // Add button (only show when there are entries)
        if (_controller.entries.isNotEmpty)
          PortfolioAddButton(
            appTheme: _appTheme,
            onTap: _showAddEntryModal,
          ),
      ],
    );
  }

  Widget _buildEntriesList(double padding) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12),
      itemCount: _controller.entries.length,
      itemBuilder: (context, index) {
        final entry = _controller.entries[index];
        final convertedAmount = _controller.getConvertedAmount(entry);

        return PortfolioEntryCard(
          entry: entry,
          baseCurrency: _controller.baseCurrency,
          convertedAmount: convertedAmount,
          appTheme: _appTheme,
          formatAmount: _controller.formatAmount,
          onAmountChanged: (newAmount) =>
              _controller.updateEntryAmount(entry.id, newAmount),
          onRemove: () => _removeEntry(entry.id),
        );
      },
    );
  }
}
