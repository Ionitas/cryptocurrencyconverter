import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting portfolio and converter data
class PortfolioStorageService {
  static const String _portfolioEntriesKey = 'portfolio_entries';
  static const String _portfolioBaseCurrencyKey = 'portfolio_base_currency';
  static const String _converterAmountKey = 'converter_last_amount';
  static const String _converterCurrencyKey = 'converter_last_currency';

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
}
