import '/services/api_exchange_rate_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/currency.dart';
import '../models/currency_row.dart';
import '../models/exchange_rate.dart';
import '../services/exchange_rate_service.dart';
//import '../services/mock_exchange_rate_service.dart';
import '../services/database_service.dart';
import '../utils/number_formatter.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Maximum number of currency rows to display in the converter
const int kNumberOfCurrencyRows = 5;

/// Maximum allowed length for calculator input to prevent overflow
const int kMaxCalculatorInputLength = 15;

final exchangeRateServiceProvider = Provider<ExchangeRateService>((ref) {
  //return MockExchangeRateService();
  return ApiExchangeRateService();
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final exchangeRatesProvider =
    StateNotifierProvider<ExchangeRatesNotifier, AsyncValue<ExchangeRate>>(
        (ref) {
  return ExchangeRatesNotifier(ref.watch(exchangeRateServiceProvider),
      ref.watch(databaseServiceProvider));
});

class ExchangeRatesNotifier extends StateNotifier<AsyncValue<ExchangeRate>> {
  final ExchangeRateService _service;
  final DatabaseService _database;

  ExchangeRatesNotifier(this._service, this._database)
      : super(const AsyncValue.loading()) {
    _loadRates();
  }

  Future<void> _loadRates() async {
    try {
      final cachedRates = await _database.loadExchangeRate();

      if (cachedRates != null) {
        state = AsyncValue.data(cachedRates);

        final now = DateTime.now();
        final diff = now.difference(cachedRates.lastUpdated);
        if (diff.inHours < 24) {
          return;
        }
      }

      await refreshRates();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshRates() async {
    state = const AsyncValue.loading();
    try {
      final rates = await _service.fetchRates();
      await _database.saveExchangeRate(rates);
      state = AsyncValue.data(rates);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final currencyRowsProvider =
    StateNotifierProvider<CurrencyRowsNotifier, List<CurrencyRow>>((ref) {
  return CurrencyRowsNotifier(ref.watch(databaseServiceProvider), ref);
});

class CurrencyRowsNotifier extends StateNotifier<List<CurrencyRow>> {
  final DatabaseService _database;
  final Ref _ref;

  CurrencyRowsNotifier(this._database, this._ref)
      : super(
          Currencies.defaults
              .asMap()
              .entries
              .map((entry) => CurrencyRow(
                  currency: entry.value,
                  displayValue: '',
                  isActive: entry.key == 0))
              .toList(),
        ) {
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final savedCodes = await _database.loadSelectedCurrencies();

    final currencies =
        (savedCodes != null && savedCodes.length == kNumberOfCurrencyRows)
            ? savedCodes
                .map((code) => Currencies.all.firstWhere((c) => c.code == code,
                    orElse: () => Currencies.usd))
                .toList()
            : Currencies.defaults;

    final activeState = await _database.loadActiveRowState();
    var activeIndex = activeState?.index ?? 0;
    final activeValue = activeState?.value ?? '';

    if (activeIndex < 0 || activeIndex >= currencies.length) {
      activeIndex = 0;
    }

    state = currencies
        .asMap()
        .entries
        .map(
          (entry) => CurrencyRow(
            currency: entry.value,
            displayValue: entry.key == activeIndex ? activeValue : '',
            isActive: entry.key == activeIndex,
          ),
        )
        .toList();

    // Recalculate converted values if there's an active value
    if (activeValue.isNotEmpty) {
      final exchangeRates = _ref.read(exchangeRatesProvider);
      exchangeRates.whenData((rates) {
        updateConvertedValues(rates);
      });
    }
  }

  Future<void> _saveCurrencies() async {
    final codes = state.map((row) => row.currency.code).toList();
    await _database.saveSelectedCurrencies(codes);
  }

  Future<void> _saveActiveState() async {
    final activeIndex = state.indexWhere((row) => row.isActive);
    if (activeIndex == -1) return;

    final activeValue = state[activeIndex].displayValue;
    await _database.saveActiveRowState(activeIndex, activeValue);
  }

  Future<void> saveState() async {
    await _saveCurrencies();
    await _saveActiveState();
  }

  void setActiveRow(int index) {
    state = [
      for (int i = 0; i < state.length; i++)
        state[i].copyWith(isActive: i == index)
    ];
    _saveActiveState();
  }

  void updateActiveRowValue(String value) {
    final activeIndex = state.indexWhere((row) => row.isActive);
    if (activeIndex == -1) return;

    state = [
      for (int i = 0; i < state.length; i++)
        if (i == activeIndex)
          state[i].copyWith(displayValue: value)
        else
          state[i],
    ];
  }

  void updateConvertedValues(ExchangeRate exchangeRate) {
    final activeRow =
        state.firstWhere((row) => row.isActive, orElse: () => state.first);
    final activeValue = activeRow.numericValue;

    if (activeValue == null) {
      state = [
        for (final row in state)
          if (!row.isActive) row.copyWith(displayValue: '') else row,
      ];
      return;
    }

    state = [
      for (final row in state)
        if (row.isActive)
          row
        else
          row.copyWith(
            displayValue: _formatNumber(exchangeRate.convert(
                activeRow.currency.code, row.currency.code, activeValue)),
          ),
    ];
  }

  void changeCurrency(int index, Currency newCurrency) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i == index)
          state[i].copyWith(currency: newCurrency, displayValue: '')
        else
          state[i],
    ];
    saveState();
  }

  void clearActiveRow() {
    final activeIndex = state.indexWhere((row) => row.isActive);
    if (activeIndex == -1) return;

    state = [
      for (int i = 0; i < state.length; i++)
        if (i == activeIndex) state[i].copyWith(displayValue: '') else state[i],
    ];
    _saveActiveState();
  }

  void clearAllRows() {
    state = [for (final row in state) row.copyWith(displayValue: '')];
    _saveActiveState();
  }

  String _formatNumber(double value) {
    return NumberFormatter.formatDisplay(value);
  }
}

final calculatorProvider =
    StateNotifierProvider<CalculatorNotifier, String>((ref) {
  return CalculatorNotifier(ref);
});

class CalculatorNotifier extends StateNotifier<String> {
  final Ref _ref;
  String _firstOperand = '';
  String _operator = '';
  bool _shouldResetDisplay = false;

  CalculatorNotifier(this._ref) : super('');

  void inputDigit(String digit) {
    final normalizedDigit = digit == ',' ? '.' : digit;

    if (_shouldResetDisplay) {
      state = normalizedDigit;
      _shouldResetDisplay = false;
      _updateActiveRow(state);
      return;
    }

    // Prevent multiple decimal points
    if (normalizedDigit == '.' && state.contains('.')) return;

    // Limit total length to prevent overflow
    if (state.length >= kMaxCalculatorInputLength && normalizedDigit != '.')
      return;

    if (state.isEmpty && normalizedDigit == '.') {
      state = '0.';
    } else if (state == '0' && normalizedDigit != '.') {
      state = normalizedDigit;
    } else {
      state = state + normalizedDigit;
    }

    _updateActiveRow(state);
  }

  void clear({clearAllRows = true}) {
    state = '';
    _firstOperand = '';
    _operator = '';
    _shouldResetDisplay = false;
    if (clearAllRows) _ref.read(currencyRowsProvider.notifier).clearAllRows();
  }

  void backspace() {
    if (state.isEmpty) return;
    state = state.substring(0, state.length - 1);
    _updateActiveRow(state);
  }

  void setOperator(String op) {
    if (state.isEmpty) return;
    if (_firstOperand.isNotEmpty && _operator.isNotEmpty) _calculate();
    _firstOperand = state;
    _operator = op;
    _shouldResetDisplay = true;
  }

  void equals() {
    if (_firstOperand.isEmpty || _operator.isEmpty || state.isEmpty) return;
    _calculate();
    _firstOperand = '';
    _operator = '';
    _shouldResetDisplay = true;
  }

  void _calculate() {
    final first = double.tryParse(_firstOperand);
    final second = double.tryParse(state);

    if (first == null || second == null) return;

    double result;
    switch (_operator) {
      case '+':
        result = first + second;
        break;
      case '-':
        result = first - second;
        break;
      case '*':
        result = first * second;
        break;
      case '/':
        if (second == 0) return;
        result = first / second;
        break;
      default:
        return;
    }

    state = NumberFormatter.formatResult(result);
    _updateActiveRow(state);
  }

  void _updateActiveRow(String value) {
    _ref.read(currencyRowsProvider.notifier).updateActiveRowValue(value);
    final exchangeRates = _ref.read(exchangeRatesProvider);
    exchangeRates.whenData((rates) {
      _ref.read(currencyRowsProvider.notifier).updateConvertedValues(rates);
    });
  }
}
