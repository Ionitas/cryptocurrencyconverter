import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/services/analytics/logging_system.dart';
import '../../domain/models/currency.dart';

/// Data source for fetching exchange rates from Supabase
///
/// This replaces direct API calls to CoinCap/CoinGecko/ExchangeRate APIs
/// with calls to our Supabase backend, which caches rates and updates them
/// periodically (3-5 times per day).
class SupabaseDataSource {
  final SupabaseClient _client;
  static const String _tag = 'Supabase';

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
      AppLogger.e(_tag, 'Not configured - check supabase_config.dart');
      throw Exception('Supabase is not configured. Please update supabase_config.dart');
    }

    AppLogger.networkRequest('${SupabaseConfig.exchangeRatesTable} (all rates)');
    final startTime = DateTime.now();

    try {
      final response = await _client
          .from(SupabaseConfig.exchangeRatesTable)
          .select()
          .order('is_crypto', ascending: false)
          .order('rank', ascending: true, nullsFirst: false)
          .order('code', ascending: true);

      final duration = DateTime.now().difference(startTime);
      final rates = _parseRates(response);
      AppLogger.networkResponse('${SupabaseConfig.exchangeRatesTable}', 200, duration);
      AppLogger.s(_tag, 'Fetched ${rates.length} rates in ${duration.inMilliseconds}ms');
      return rates;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      AppLogger.networkResponse('${SupabaseConfig.exchangeRatesTable}', 500, duration);
      AppLogger.e(_tag, 'fetchAllRates failed', error: e);
      rethrow;
    }
  }

  /// Fetches only cryptocurrency rates from Supabase
  Future<List<Currency>> fetchCryptoRates({int? limit}) async {
    if (!isConfigured) {
      throw Exception('Supabase is not configured');
    }

    AppLogger.networkRequest('${SupabaseConfig.exchangeRatesTable} (crypto only, limit: $limit)');
    final startTime = DateTime.now();

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
      final duration = DateTime.now().difference(startTime);
      final rates = _parseRates(response);
      AppLogger.networkResponse('${SupabaseConfig.exchangeRatesTable} (crypto)', 200, duration);
      return rates;
    } catch (e) {
      AppLogger.e(_tag, 'fetchCryptoRates failed', error: e);
      rethrow;
    }
  }

  /// Fetches only fiat currency rates from Supabase
  Future<List<Currency>> fetchFiatRates() async {
    if (!isConfigured) {
      throw Exception('Supabase is not configured');
    }

    AppLogger.networkRequest('${SupabaseConfig.exchangeRatesTable} (fiat only)');
    final startTime = DateTime.now();

    try {
      final response = await _client
          .from(SupabaseConfig.exchangeRatesTable)
          .select()
          .eq('is_crypto', false)
          .order('code', ascending: true);

      final duration = DateTime.now().difference(startTime);
      final rates = _parseRates(response);
      AppLogger.networkResponse('${SupabaseConfig.exchangeRatesTable} (fiat)', 200, duration);
      return rates;
    } catch (e) {
      AppLogger.e(_tag, 'fetchFiatRates failed', error: e);
      rethrow;
    }
  }

  /// Gets the last update timestamp from Supabase
  Future<DateTime?> getLastUpdateTime() async {
    if (!isConfigured) return null;

    AppLogger.d(_tag, 'Fetching last update time...');

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
          final dt = DateTime.parse(timestamp);
          AppLogger.d(_tag, 'Last update: $timestamp');
          return dt;
        }
      }
      AppLogger.d(_tag, 'No last update time found');
      return null;
    } catch (e) {
      AppLogger.e(_tag, 'getLastUpdateTime failed', error: e);
      return null;
    }
  }

  /// Gets the update status from Supabase
  Future<Map<String, dynamic>?> getUpdateStatus() async {
    if (!isConfigured) return null;

    try {
      final response =
          await _client.from(SupabaseConfig.lastUpdateStatusView).select().maybeSingle();

      AppLogger.d(_tag, 'Update status: $response');
      return response;
    } catch (e) {
      AppLogger.e(_tag, 'getUpdateStatus failed', error: e);
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
        lastUpdated:
            data['updated_at'] != null ? DateTime.tryParse(data['updated_at'].toString()) : null,
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
