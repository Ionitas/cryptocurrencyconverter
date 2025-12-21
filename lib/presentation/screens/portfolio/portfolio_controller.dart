import 'package:flutter/foundation.dart';
import '../../../domain/models/currency.dart';
import '../../../domain/repositories/currency_repository.dart';

/// Model for a portfolio entry (currency + amount)
class PortfolioEntry {
  final String id;
  final Currency currency;
  double amount;

  PortfolioEntry({
    required this.id,
    required this.currency,
    required this.amount,
  });

  PortfolioEntry copyWith({
    String? id,
    Currency? currency,
    double? amount,
  }) {
    return PortfolioEntry(
      id: id ?? this.id,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
    );
  }
}

/// Business logic controller for the portfolio screen
class PortfolioController extends ChangeNotifier {
  final CurrencyRepository repository;

  PortfolioController({required this.repository});

  // State
  List<Currency> _allCurrencies = [];
  Currency? _baseCurrency;
  List<PortfolioEntry> _entries = [];
  bool _isLoading = true;

  // Getters
  List<Currency> get allCurrencies => _allCurrencies;
  Currency? get baseCurrency => _baseCurrency;
  List<PortfolioEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  int get entryCount => _entries.length;

  /// Calculate total value in base currency
  double get total {
    if (_baseCurrency == null) return 0.0;

    double sum = 0.0;
    for (final entry in _entries) {
      sum += repository.convert(entry.amount, entry.currency, _baseCurrency!);
    }
    return sum;
  }

  /// Load currencies from repository
  Future<void> loadCurrencies() async {
    _isLoading = true;
    notifyListeners();

    final result = await repository.loadCurrencies();

    if (result.currencies.isNotEmpty) {
      _allCurrencies = result.currencies;
      // Default to USD as base currency
      _baseCurrency = _allCurrencies.firstWhere(
        (c) => c.symbol == 'USD',
        orElse: () => _allCurrencies.first,
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Change the base currency for conversion
  void setBaseCurrency(Currency currency) {
    _baseCurrency = currency;
    notifyListeners();
  }

  /// Add a new entry to the portfolio
  void addEntry(Currency currency, double amount) {
    _entries.add(PortfolioEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      currency: currency,
      amount: amount,
    ));
    notifyListeners();
  }

  /// Update the amount of an existing entry
  void updateEntryAmount(String id, double newAmount) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      _entries[index].amount = newAmount;
      notifyListeners();
    }
  }

  /// Remove an entry from the portfolio
  PortfolioEntry? removeEntry(String id) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      final removed = _entries.removeAt(index);
      notifyListeners();
      return removed;
    }
    return null;
  }

  /// Get converted amount for a specific entry
  double getConvertedAmount(PortfolioEntry entry) {
    if (_baseCurrency == null) return 0.0;
    return repository.convert(entry.amount, entry.currency, _baseCurrency!);
  }

  /// Format amount for display
  String formatAmount(double amount) {
    if (amount == 0) return '0';
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    }
    if (amount >= 1000) {
      return amount.toStringAsFixed(2);
    }
    if (amount >= 1) {
      return amount.toStringAsFixed(4);
    }
    if (amount >= 0.0001) {
      return amount.toStringAsFixed(6);
    }
    return amount.toStringAsExponential(2);
  }
}
