/// Supabase configuration for the app
///
/// Replace the placeholder values with your actual Supabase project credentials.
/// You can find these in your Supabase Dashboard > Settings > API
class SupabaseConfig {
  SupabaseConfig._();

  /// Supabase Project URL
  static const String supabaseUrl = 'https://wvnjhqrasmtbyupipdfz.supabase.co';

  /// Supabase Anonymous Key (safe to expose in client)
  /// This key has limited permissions defined by RLS policies
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2bmpocXJhc210Ynl1cGlwZGZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY1Nzg1NzUsImV4cCI6MjA4MjE1NDU3NX0.Uh0jhcz8bN-jeHGEm8GJ_bJ_ML_N0h771iu2ZPl1Nds';

  /// Table names
  static const String exchangeRatesTable = 'exchange_rates';
  static const String rateUpdateLogsTable = 'rate_update_logs';
  static const String appMetadataTable = 'app_metadata';

  /// View names
  static const String cryptoRatesView = 'crypto_rates';
  static const String fiatRatesView = 'fiat_rates';
  static const String lastUpdateStatusView = 'last_update_status';

  /// Check if Supabase is configured
  static bool get isConfigured =>
      supabaseUrl != 'https://YOUR_PROJECT_REF.supabase.co' &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';
}
