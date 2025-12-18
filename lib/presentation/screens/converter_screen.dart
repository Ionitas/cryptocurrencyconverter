import 'package:flutter/material.dart';
import '../../domain/models/currency.dart';
import '../../domain/repositories/currency_repository.dart';
import '../../core/di/injection.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../utils/calculator_logic.dart';
import '../utils/snackbar_helper.dart';

/// Main converter screen for currency conversion
class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen>
    with TickerProviderStateMixin, CalculatorLogic {
  final CurrencyRepository _repository = getIt<CurrencyRepository>();
  final AppTheme _appTheme = getIt<AppTheme>();

  // Currency data
  List<Currency> _allCurrencies = [];
  Currency? _selectedCurrency;
  List<Currency> _displayCurrencies = [];
  List<String> _displayCurrencyOrder = [
    'USD',
    'EUR',
    'ETH',
    'GBP',
    'JPY',
    'USDT'
  ];
  Set<String> _displayCurrencySymbols = {
    'USD',
    'EUR',
    'ETH',
    'GBP',
    'JPY',
    'USDT'
  };

  // UI state
  bool _isLoading = true;
  String _statusMessage = '';
  bool _fromCache = false;
  bool _isCalculatorVisible = true;

  @override
  void initState() {
    super.initState();
    currentAmount = 0.5;
    displayValue = '0.5';
    _appTheme.addListener(_onThemeChanged);
    _loadData();
  }

  @override
  void dispose() {
    _appTheme.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _statusMessage = forceRefresh ? 'Fetching fresh data...' : 'Loading...';
    });

    final result = await _repository.loadCurrencies(forceRefresh: forceRefresh);

    if (result.currencies.isNotEmpty) {
      _allCurrencies = result.currencies;
      _selectedCurrency = _allCurrencies.firstWhere(
        (c) => c.symbol == 'BTC',
        orElse: () => _allCurrencies.first,
      );
      _updateDisplayCurrencies();
    }

    setState(() {
      _isLoading = false;
      _fromCache = result.fromCache;
      _statusMessage = result.message;
    });

    if (mounted) {
      _showDataSnackBar(result.fromCache);
    }
  }

  void _showDataSnackBar(bool fromCache) {
    SnackBarHelper.show(
      context: context,
      message: fromCache
          ? '✓ Loaded from cache (${_allCurrencies.length} currencies)'
          : '✓ Fresh data (${_allCurrencies.length} currencies)',
      appTheme: _appTheme,
      type: fromCache ? SnackBarType.warning : SnackBarType.success,
    );
  }

  void _updateDisplayCurrencies() {
    final currencyMap = {for (var c in _allCurrencies) c.symbol: c};
    _displayCurrencies = _displayCurrencyOrder
        .where((symbol) =>
            _displayCurrencySymbols.contains(symbol) &&
            currencyMap.containsKey(symbol) &&
            currencyMap[symbol]!.id != _selectedCurrency?.id)
        .map((symbol) => currencyMap[symbol]!)
        .toList();
  }

  void _removeCurrency(Currency currency) {
    setState(() {
      _displayCurrencySymbols.remove(currency.symbol);
      _displayCurrencyOrder.remove(currency.symbol);
      _updateDisplayCurrencies();
    });
  }

  void _addCurrency(Currency currency) {
    setState(() {
      _displayCurrencySymbols.add(currency.symbol);
      if (!_displayCurrencyOrder.contains(currency.symbol)) {
        _displayCurrencyOrder.add(currency.symbol);
      }
      _updateDisplayCurrencies();
    });

    SnackBarHelper.show(
      context: context,
      message: '${currency.symbol} added',
      appTheme: _appTheme,
      type: SnackBarType.success,
      duration: const Duration(seconds: 1),
    );
  }

  void _onReorderCurrencies(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final currency = _displayCurrencies.removeAt(oldIndex);
      _displayCurrencies.insert(newIndex, currency);
      _displayCurrencyOrder = _displayCurrencies.map((c) => c.symbol).toList();
      for (var symbol in _displayCurrencySymbols) {
        if (!_displayCurrencyOrder.contains(symbol)) {
          _displayCurrencyOrder.add(symbol);
        }
      }
    });
  }

  void _swapCurrency(Currency currency, int index) {
    setState(() {
      final convertedAmount = _repository.convert(
        currentAmount,
        _selectedCurrency!,
        currency,
      );

      _displayCurrencySymbols.add(_selectedCurrency!.symbol);
      if (!_displayCurrencyOrder.contains(_selectedCurrency!.symbol)) {
        _displayCurrencyOrder.insert(index, _selectedCurrency!.symbol);
      }
      _displayCurrencySymbols.remove(currency.symbol);
      _displayCurrencyOrder.remove(currency.symbol);
      _selectedCurrency = currency;
      currentAmount = convertedAmount;
      displayValue = formatCalculatorResult(convertedAmount);
      calculatorExpression = '';
      previousValue = null;
      operation = null;
      shouldResetDisplay = true;
      _updateDisplayCurrencies();
    });

    SnackBarHelper.show(
      context: context,
      message: '${currency.symbol} is now the main currency',
      appTheme: _appTheme,
      type: SnackBarType.info,
      duration: const Duration(seconds: 1),
    );
  }

  void _onCalculatorInput(String value) {
    setState(() {
      handleCalculatorInput(value);
    });
  }

  void _showAddCurrencyPicker() {
    final availableCurrencies = _allCurrencies
        .where((c) =>
            !_displayCurrencySymbols.contains(c.symbol) &&
            c.id != _selectedCurrency?.id)
        .toList();

    AddCurrencyModal.show(
      context: context,
      availableCurrencies: availableCurrencies,
      onAdd: _addCurrency,
    );
  }

  Future<void> _showSettings() async {
    final lastUpdate = await _repository.getLastUpdateTime();
    final nextUpdate = _repository.getNextUpdateTime();

    if (!mounted) return;

    SettingsDialog.show(
      context: context,
      fromCache: _fromCache,
      nextUpdate: nextUpdate,
      lastUpdate: lastUpdate,
      currencyCount: _allCurrencies.length,
      onForceRefresh: () => _loadData(forceRefresh: true),
      appTheme: _appTheme,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appTheme.background,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingView() : _buildMainContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _appTheme.background,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        'Currency Converter',
        style: TextStyle(
          color: _appTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: _appTheme.textPrimary),
          onPressed: () => _loadData(forceRefresh: true),
        ),
        IconButton(
          icon: Icon(Icons.settings, color: _appTheme.textPrimary),
          onPressed: _showSettings,
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _statusMessage,
            style: TextStyle(color: _appTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          child: InputSection(
            key: ValueKey(_selectedCurrency?.symbol),
            selectedCurrency: _selectedCurrency,
            displayValue: displayValue,
            calculatorExpression: calculatorExpression,
            appTheme: _appTheme,
            onTap: () {
              if (!_isCalculatorVisible) {
                setState(() => _isCalculatorVisible = true);
              }
            },
          ),
        ),
        Expanded(child: _buildCurrencyList()),
        _buildBottomSection(),
      ],
    );
  }

  Widget _buildCurrencyList() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: _buildListHeader(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverReorderableList(
            itemBuilder: (context, index) {
              final currency = _displayCurrencies[index];
              return CurrencyCard(
                key: ValueKey(currency.symbol),
                currency: currency,
                selectedCurrency: _selectedCurrency!,
                index: index,
                convertedAmount: _repository.convert(
                  currentAmount,
                  _selectedCurrency!,
                  currency,
                ),
                exchangeRate:
                    _repository.convert(1.0, _selectedCurrency!, currency),
                appTheme: _appTheme,
                onTap: () => _swapCurrency(currency, index),
                onDismissed: () => _removeCurrency(currency),
                onUndo: () => _addCurrency(currency),
                formatAmount: formatAmount,
              );
            },
            itemCount: _displayCurrencies.length,
            onReorder: _onReorderCurrencies,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                AddCurrencyCard(
                    appTheme: _appTheme, onTap: _showAddCurrencyPicker),
                const SizedBox(height: 8),
                PremiumCard(
                  appTheme: _appTheme,
                  onUpgrade: () async {
                    await _repository.setPremium(true);
                    if (mounted) _loadData(forceRefresh: true);
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'CONVERTED VALUES',
          style: TextStyle(
            color: _appTheme.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        Row(
          children: [
            Icon(Icons.drag_handle, color: _appTheme.textTertiary, size: 14),
            const SizedBox(width: 4),
            Text(
              '${_displayCurrencies.length} currencies',
              style: TextStyle(color: _appTheme.textTertiary, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    if (_isCalculatorVisible) {
      return CalculatorPad(
        appTheme: _appTheme,
        onInput: _onCalculatorInput,
        onHide: () => setState(() => _isCalculatorVisible = false),
      );
    }
    return BottomBar(
      appTheme: _appTheme,
      onAddCurrency: _showAddCurrencyPicker,
      onShowCalculator: () => setState(() => _isCalculatorVisible = true),
    );
  }
}
