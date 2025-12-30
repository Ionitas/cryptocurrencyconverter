import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../domain/models/currency.dart';

/// Data source for fetching exchange rates from Supabase
///
/// This replaces direct API calls to CoinCap/CoinGecko/ExchangeRate APIs
/// with calls to our Supabase backend, which caches rates and updates them
/// periodically (3-5 times per day).
class SupabaseDataSource {
  final SupabaseClient _client;

  SupabaseDataSource(this._client);

  /// Factory constructor using the global Supabase client
  factory SupabaseDataSource.instance() {
    return SupabaseDataSource(Supabase.instance.client);
  }

  /// Check if Supabase is properly configured
  bool get isConfigured => SupabaseConfig.isConfigured;

  /// Fetches all exchange rates (crypto + fiat) from Supabase
  Future<List<Currency>> fetchAllRates() async {
    if (!isConfigured) {
      throw Exception(
          'Supabase is not configured. Please update supabase_config.dart');
    }

    try {
      final response = await _client
          .from(SupabaseConfig.exchangeRatesTable)
          .select()
          .order('is_crypto', ascending: false)
          .order('rank', ascending: true, nullsFirst: false)
          .order('code', ascending: true);

      return _parseRates(response);
    } catch (e) {
      print('Supabase fetchAllRates error: $e');
      rethrow;
    }
  }

  /// Fetches only cryptocurrency rates from Supabase
  Future<List<Currency>> fetchCryptoRates({int? limit}) async {
    if (!isConfigured) {
      throw Exception('Supabase is not configured');
    }

    try {
      var query = _client
          .from(SupabaseConfig.exchangeRatesTable)
          .select()
          .eq('is_crypto', true)
          .order('rank', ascending: true, nullsFirst: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return _parseRates(response);
    } catch (e) {
      print('Supabase fetchCryptoRates error: $e');
      rethrow;
    }
  }

  /// Fetches only fiat currency rates from Supabase
  Future<List<Currency>> fetchFiatRates() async {
    if (!isConfigured) {
      throw Exception('Supabase is not configured');
    }

    try {
      final response = await _client
          .from(SupabaseConfig.exchangeRatesTable)
          .select()
          .eq('is_crypto', false)
          .order('code', ascending: true);

      return _parseRates(response);
    } catch (e) {
      print('Supabase fetchFiatRates error: $e');
      rethrow;
    }
  }

  /// Gets the last update timestamp from Supabase
  Future<DateTime?> getLastUpdateTime() async {
    if (!isConfigured) return null;

    try {
      final response = await _client
          .from(SupabaseConfig.appMetadataTable)
          .select('value')
          .eq('key', 'last_rate_update')
          .maybeSingle();

      if (response != null && response['value'] != null) {
        final value = response['value'] as Map<String, dynamic>;
        final timestamp = value['timestamp'] as String?;
        if (timestamp != null) {
          return DateTime.parse(timestamp);
        }
      }
      return null;
    } catch (e) {
      print('Supabase getLastUpdateTime error: $e');
      return null;
    }
  }

  /// Gets the update status from Supabase
  Future<Map<String, dynamic>?> getUpdateStatus() async {
    if (!isConfigured) return null;

    try {
      final response = await _client
          .from(SupabaseConfig.lastUpdateStatusView)
          .select()
          .maybeSingle();

      return response;
    } catch (e) {
      print('Supabase getUpdateStatus error: $e');
      return null;
    }
  }

  /// Parses the Supabase response into Currency objects
  List<Currency> _parseRates(List<dynamic> response) {
    return response.map((row) {
      final data = row as Map<String, dynamic>;
      return Currency(
        id: data['code']?.toString().toLowerCase() ?? '',
        code: data['code'] ?? '',
        name: data['name'] ?? '',
        symbol: data['symbol'] ?? data['code'] ?? '',
        priceUsd: _parseDouble(data['price_usd']),
        changePercent24h: _parseDouble(data['change_percent_24h']),
        isCrypto: data['is_crypto'] ?? false,
        lastUpdated: data['updated_at'] != null
            ? DateTime.tryParse(data['updated_at'].toString())
            : null,
      );
    }).toList();
  }

  /// Safely parses a dynamic value to double
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
