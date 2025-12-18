import 'package:flutter/material.dart';
import '../../domain/models/currency.dart';
import '../../domain/repositories/currency_repository.dart';
import '../../core/di/injection.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen>
    with TickerProviderStateMixin {
  final CurrencyRepository _repository = getIt<CurrencyRepository>();
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
  double _currentAmount = 0.5;
  bool _isLoading = true;
  String _statusMessage = '';
  bool _fromCache = false;

  // Calculator state
  bool _isCalculatorVisible = true;
  String _displayValue = '0.5';
  String _calculatorExpression = '';
  double? _previousValue;
  String? _operation;
  bool _shouldResetDisplay = false;

  @override
  void initState() {
    super.initState();
    _loadData();
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
      _displayValue = _currentAmount.toString();
      _updateDisplayCurrencies();
    }

    setState(() {
      _isLoading = false;
      _fromCache = result.fromCache;
      _statusMessage = result.message;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.fromCache
                ? '✓ Loaded from cache (${_allCurrencies.length} currencies)'
                : '✓ Fresh data (${_allCurrencies.length} currencies)',
          ),
          backgroundColor: result.fromCache ? Colors.orange : Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
  }

  void _onReorderCurrencies(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final currency = _displayCurrencies.removeAt(oldIndex);
      _displayCurrencies.insert(newIndex, currency);
      // Update the order list
      _displayCurrencyOrder = _displayCurrencies.map((c) => c.symbol).toList();
      // Add back any symbols not currently displayed
      for (var symbol in _displayCurrencySymbols) {
        if (!_displayCurrencyOrder.contains(symbol)) {
          _displayCurrencyOrder.add(symbol);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F2E),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Currency Converter',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadData(forceRefresh: true),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
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
                      child: _buildInputSection(),
                    ),
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverToBoxAdapter(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'CONVERTED VALUES',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.drag_handle,
                                        color: Color(0xFF6B7280),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_displayCurrencies.length} currencies',
                                        style: const TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverReorderableList(
                              itemBuilder: (context, index) {
                                final currency = _displayCurrencies[index];
                                return _buildCurrencyCard(
                                  currency,
                                  index,
                                  key: ValueKey(currency.symbol),
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
                                  _buildAddCurrencyCard(),
                                  const SizedBox(height: 8),
                                  _buildPremiumCard(),
                                  const SizedBox(height: 80),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isCalculatorVisible) _buildCalculatorPad(),
                  ],
                ),
                // Floating calculator button
                if (!_isCalculatorVisible)
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: FloatingActionButton(
                      onPressed: () {
                        setState(() {
                          _isCalculatorVisible = true;
                        });
                      },
                      backgroundColor: const Color(0xFF3B7FFF),
                      child: const Icon(Icons.calculate, color: Colors.white),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      key: ValueKey(_selectedCurrency?.symbol ?? 'none'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252B3D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3B7FFF),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You convert',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _displayValue,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildCurrencyIcon(_selectedCurrency),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedCurrency?.symbol ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _selectedCurrency?.name ?? '',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyIcon(Currency? currency) {
    if (currency == null) return const SizedBox();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: currency.isCrypto
            ? Colors.orange.withOpacity(0.2)
            : Colors.blue.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          currency.displayFlag,
          style: const TextStyle(
            fontSize: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyCard(Currency currency, int index, {Key? key}) {
    if (_selectedCurrency == null) return const SizedBox();

    final convertedAmount = _repository.convert(
      _currentAmount,
      _selectedCurrency!,
      currency,
    );

    // Calculate exchange rate: 1 unit of selected currency = X units of target currency
    final exchangeRate = _repository.convert(
      1.0,
      _selectedCurrency!,
      currency,
    );

    return Dismissible(
      key: key ?? Key('dismissible_${currency.symbol}'),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _removeCurrency(currency);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${currency.symbol} removed'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => _addCurrency(currency),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () {
          setState(() {
            // Add current main currency to display list
            _displayCurrencySymbols.add(_selectedCurrency!.symbol);
            if (!_displayCurrencyOrder.contains(_selectedCurrency!.symbol)) {
              _displayCurrencyOrder.insert(index, _selectedCurrency!.symbol);
            }
            // Remove the tapped currency from display list
            _displayCurrencySymbols.remove(currency.symbol);
            _displayCurrencyOrder.remove(currency.symbol);
            // Set the tapped currency as main
            _selectedCurrency = currency;
            _updateDisplayCurrencies();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${currency.symbol} is now the main currency'),
              backgroundColor: const Color(0xFF3B7FFF),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF252B3D),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.drag_indicator,
                    color: Color(0xFF4B5563),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildCurrencyIcon(currency),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currency.symbol,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      currency.name,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatAmount(convertedAmount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '1 ${_selectedCurrency!.symbol} = ${_formatAmount(exchangeRate)} ${currency.symbol}',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddCurrencyCard() {
    return GestureDetector(
      onTap: _showAddCurrencyPicker,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF252B3D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF3B7FFF).withOpacity(0.5),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF3B7FFF).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Color(0xFF3B7FFF),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Add Currency',
              style: TextStyle(
                color: Color(0xFF3B7FFF),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCurrencyPicker() {
    final availableCurrencies = _allCurrencies
        .where((c) =>
            !_displayCurrencySymbols.contains(c.symbol) &&
            c.id != _selectedCurrency?.id)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF252B3D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext modalContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Currency',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${availableCurrencies.length} available',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: availableCurrencies.length,
                itemBuilder: (context, index) {
                  final currency = availableCurrencies[index];
                  return ListTile(
                    leading: _buildCurrencyIcon(currency),
                    title: Text(
                      currency.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      currency.symbol,
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B7FFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    onTap: () {
                      _addCurrency(currency);
                      Navigator.pop(modalContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${currency.symbol} added'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 1),
                        ),
                      );
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

  Widget _buildPremiumCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF252B3D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B7FFF), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B7FFF).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Color(0xFF3B7FFF),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Unlock All 150+ Currencies',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Get real-time rates, unlimited conversions & premium charts.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await _repository.setPremium(true);
                if (mounted) {
                  _loadData(forceRefresh: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B7FFF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Upgrade to Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorPad() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFF252B3D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with expression and hide button
            Row(
              children: [
                // Expression display
                Expanded(
                  child: _calculatorExpression.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1F2E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _calculatorExpression,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        )
                      : const SizedBox(),
                ),
                const SizedBox(width: 8),
                // Hide button (small icon button)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isCalculatorVisible = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B7FFF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.keyboard_hide,
                      color: Color(0xFF3B7FFF),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Calculator buttons
            Row(
              children: [
                _buildCalcButton('C', isFunction: true),
                _buildCalcButton('AC', isFunction: true),
                _buildCalcButton('⌫', isFunction: true),
                _buildCalcButton('÷', isOperation: true),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildCalcButton('7'),
                _buildCalcButton('8'),
                _buildCalcButton('9'),
                _buildCalcButton('×', isOperation: true),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildCalcButton('4'),
                _buildCalcButton('5'),
                _buildCalcButton('6'),
                _buildCalcButton('-', isOperation: true),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildCalcButton('1'),
                _buildCalcButton('2'),
                _buildCalcButton('3'),
                _buildCalcButton('+', isOperation: true),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildCalcButton('0'),
                _buildCalcButton('.'),
                _buildCalcButton('=', isEquals: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalcButton(String value,
      {bool isOperation = false,
      bool isFunction = false,
      bool isEquals = false}) {
    Color backgroundColor = const Color(0xFF1A1F2E);
    Color textColor = Colors.white;
    int flex = 1;

    if (isOperation) {
      backgroundColor = const Color(0xFF3B7FFF);
    } else if (isFunction) {
      backgroundColor = const Color(0xFF374151);
    } else if (isEquals) {
      backgroundColor = const Color(0xFF10B981);
      flex = 2;
    }

    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => _handleCalculatorInput(value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleCalculatorInput(String value) {
    setState(() {
      switch (value) {
        case 'AC':
          _displayValue = '0';
          _calculatorExpression = '';
          _previousValue = null;
          _operation = null;
          _currentAmount = 0;
          _shouldResetDisplay = false;
          break;

        case 'C':
          _displayValue = '0';
          _currentAmount = 0;
          break;

        case '⌫':
          if (_displayValue.length > 1) {
            _displayValue =
                _displayValue.substring(0, _displayValue.length - 1);
            if (_displayValue == '-') _displayValue = '0';
          } else {
            _displayValue = '0';
          }
          _currentAmount = double.tryParse(_displayValue) ?? 0;
          break;

        case '+':
        case '-':
        case '×':
        case '÷':
          _previousValue = double.tryParse(_displayValue) ?? 0;
          _operation = value;
          _calculatorExpression = '$_displayValue $value';
          _shouldResetDisplay = true;
          break;

        case '=':
          if (_previousValue != null && _operation != null) {
            final currentValue = double.tryParse(_displayValue) ?? 0;
            double result = 0;

            switch (_operation) {
              case '+':
                result = _previousValue! + currentValue;
                break;
              case '-':
                result = _previousValue! - currentValue;
                break;
              case '×':
                result = _previousValue! * currentValue;
                break;
              case '÷':
                if (currentValue != 0) {
                  result = _previousValue! / currentValue;
                } else {
                  _displayValue = 'Error';
                  _previousValue = null;
                  _operation = null;
                  _calculatorExpression = '';
                  return;
                }
                break;
            }

            _displayValue = _formatCalculatorResult(result);
            _currentAmount = result;
            _calculatorExpression = '';
            _operation = null;
            _previousValue = null;
            _shouldResetDisplay = true;
          }
          break;

        case '.':
          if (_shouldResetDisplay) {
            _displayValue = '0.';
            _shouldResetDisplay = false;
          } else if (!_displayValue.contains('.')) {
            _displayValue += '.';
          }
          break;

        default:
          // Number input
          if (_shouldResetDisplay || _displayValue == '0') {
            _displayValue = value;
            _shouldResetDisplay = false;
          } else {
            _displayValue += value;
          }
          _currentAmount = double.tryParse(_displayValue) ?? 0;
          break;
      }
    });
  }

  String _formatCalculatorResult(double value) {
    if (value == value.toInt() && value.abs() < 1e10) {
      return value.toInt().toString();
    }
    String result = value.toStringAsFixed(8);
    // Remove trailing zeros after decimal point
    if (result.contains('.')) {
      result = result.replaceAll(RegExp(r'0+$'), '');
      result = result.replaceAll(RegExp(r'\.$'), '');
    }
    return result;
  }

  void _showSettings() async {
    final lastUpdate = await _repository.getLastUpdateTime();
    final nextUpdate = _repository.getNextUpdateTime();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252B3D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Data Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _fromCache
                    ? Colors.orange.withOpacity(0.2)
                    : Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _fromCache ? Icons.storage : Icons.cloud_done,
                    color: _fromCache ? Colors.orange : Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fromCache ? 'Using Cached Data' : 'Live Data',
                          style: TextStyle(
                            color: _fromCache ? Colors.orange : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _fromCache
                              ? 'Next update: $nextUpdate'
                              : 'Data is up to date',
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'The app fetches data from API twice per day (every 12 hours) and stores it locally.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (lastUpdate != null) ...[
              _buildInfoRow('Last Update', _formatDateTime(lastUpdate)),
              const SizedBox(height: 8),
            ],
            _buildInfoRow('Currencies', '${_allCurrencies.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadData(forceRefresh: true);
            },
            child: const Text(
              'Force Refresh',
              style: TextStyle(
                  color: Color(0xFF3B7FFF), fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$hour:$minute ($day/$month)';
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)}K';
    } else if (amount >= 1) {
      return amount.toStringAsFixed(2);
    } else if (amount >= 0.0001) {
      return amount.toStringAsFixed(4);
    } else {
      return amount.toStringAsFixed(8);
    }
  }
}
