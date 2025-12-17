import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/exchange_rate.dart';

class ActiveRowState {
  final int index;
  final String value;

  ActiveRowState({required this.index, required this.value});
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _boxName = 'exchange_rates';
  static const String _ratesKey = 'latest_rates';
  static const String _currenciesKey = 'selected_currencies';
  static const String _activeRowKey = 'active_row_state';

  // Cache box instance to prevent race conditions
  Box? _box;

  Future<Box> _getBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }

    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox(_boxName);
    } else {
      _box = Hive.box(_boxName);
    }

    return _box!;
  }

  Future<void> saveExchangeRate(ExchangeRate exchangeRate) async {
    final box = await _getBox();

    await box.put(_ratesKey, {
      'base_currency': exchangeRate.baseCurrency,
      'rates': json.encode(exchangeRate.rates),
      'last_updated': exchangeRate.lastUpdated.toIso8601String(),
    });
  }

  Future<ExchangeRate?> loadExchangeRate() async {
    try {
      final box = await _getBox();
      final data = box.get(_ratesKey);

      if (data == null) return null;

      if (data is! Map) {
        await clearExchangeRates();
        return null;
      }

      final baseCurrency = data['base_currency'];
      final ratesJson = data['rates'];
      final lastUpdatedStr = data['last_updated'];

      if (baseCurrency is! String || ratesJson is! String || lastUpdatedStr is! String) {
        await clearExchangeRates();
        return null;
      }

      final dynamic decodedRates = json.decode(ratesJson);
      if (decodedRates is! Map) {
        await clearExchangeRates();
        return null;
      }

      final lastUpdated = DateTime.tryParse(lastUpdatedStr);
      if (lastUpdated == null) {
        await clearExchangeRates();
        return null;
      }

      final rates = <String, double>{};
      for (final entry in decodedRates.entries) {
        if (entry.key is String && entry.value is num) {
          rates[entry.key as String] = (entry.value as num).toDouble();
        }
      }

      return ExchangeRate(baseCurrency: baseCurrency, rates: rates, lastUpdated: lastUpdated);
    } catch (e) {
      // Clear corrupted data and return null
      await clearExchangeRates();
      return null;
    }
  }

  Future<void> clearExchangeRates() async {
    final box = await _getBox();
    await box.delete(_ratesKey);
  }

  Future<void> saveSelectedCurrencies(List<String> currencyCodes) async {
    final box = await _getBox();
    await box.put(_currenciesKey, currencyCodes);
  }

  Future<List<String>?> loadSelectedCurrencies() async {
    try {
      final box = await _getBox();
      final data = box.get(_currenciesKey);

      if (data == null) return null;

      if (data is List) {
        return data.map((e) => e.toString()).toList();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> saveActiveRowState(int activeIndex, String activeValue) async {
    final box = await _getBox();
    await box.put(_activeRowKey, {
      'index': activeIndex,
      'value': activeValue,
    });
  }

  Future<ActiveRowState?> loadActiveRowState() async {
    try {
      final box = await _getBox();
      final data = box.get(_activeRowKey);

      if (data == null) return null;

      if (data is Map) {
        final index = data['index'];
        final value = data['value'];

        if (index is int && value is String) {
          return ActiveRowState(index: index, value: value);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
