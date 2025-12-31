import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics/logging_system.dart';

/// Service for persisting portfolio and converter data
class PortfolioStorageService {
  static const String _portfolioEntriesKey = 'portfolio_entries';
  static const String _portfolioBaseCurrencyKey = 'portfolio_base_currency';
  static const String _converterAmountKey = 'converter_last_amount';
  static const String _converterCurrencyKey = 'converter_last_currency';
  static const String _converterDisplayCurrenciesKey = 'converter_display_currencies';
  static const String _converterDisplayOrderKey = 'converter_display_order';

  static const String _tag = 'Storage';

  /// Save portfolio entries (list of currency symbol + amount)
  Future<void> savePortfolioEntries(List<Map<String, dynamic>> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_portfolioEntriesKey, json.encode(entries));
  }

  /// Load portfolio entries
  Future<List<Map<String, dynamic>>> loadPortfolioEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_portfolioEntriesKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Save portfolio base currency symbol
  Future<void> savePortfolioBaseCurrency(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_portfolioBaseCurrencyKey, symbol);
  }

  /// Load portfolio base currency symbol
  Future<String?> loadPortfolioBaseCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_portfolioBaseCurrencyKey);
  }

  /// Save converter last amount and currency
  Future<void> saveConverterState({
    required double amount,
    required String currencySymbol,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_converterAmountKey, amount);
    await prefs.setString(_converterCurrencyKey, currencySymbol);
  }

  /// Load converter last amount
  Future<double?> loadConverterAmount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_converterAmountKey);
  }

  /// Load converter last currency symbol
  Future<String?> loadConverterCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_converterCurrencyKey);
  }

  /// Save converter display currencies (symbols set and order list)
  Future<void> saveConverterDisplayCurrencies({
    required Set<String> symbols,
    required List<String> order,
  }) async {
    AppLogger.d(_tag, 'Saving display currencies: ${order.join(", ")}');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_converterDisplayCurrenciesKey, symbols.toList());
    await prefs.setStringList(_converterDisplayOrderKey, order);
    AppLogger.s(_tag, 'Display currencies saved successfully');
  }

  /// Load converter display currencies symbols
  Future<Set<String>?> loadConverterDisplaySymbols() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_converterDisplayCurrenciesKey);
    AppLogger.d(_tag, 'Loaded display symbols: ${list?.join(", ") ?? "null"}');
    return list != null && list.isNotEmpty ? Set<String>.from(list) : null;
  }

  /// Load converter display currencies order
  Future<List<String>?> loadConverterDisplayOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_converterDisplayOrderKey);
    AppLogger.d(_tag, 'Loaded display order: ${list?.join(", ") ?? "null"}');
    return list != null && list.isNotEmpty ? list : null;
  }
}
