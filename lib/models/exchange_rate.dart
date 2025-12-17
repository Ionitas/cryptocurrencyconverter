/// Represents exchange rates for currency conversion
///
/// Stores exchange rates relative to a [baseCurrency] and provides
/// conversion functionality between any two currencies.
class ExchangeRate {
  /// The base currency that all rates are relative to (usually USD)
  final String baseCurrency;

  /// Map of currency codes to their exchange rates relative to [baseCurrency]
  final Map<String, double> rates;

  /// When these exchange rates were last updated
  final DateTime lastUpdated;

  const ExchangeRate({
    required this.baseCurrency,
    required this.rates,
    required this.lastUpdated,
  });

  /// Converts an [amount] from one currency to another
  ///
  /// Handles three conversion scenarios:
  /// 1. Same currency: returns amount unchanged
  /// 2. From/to base currency: direct rate multiplication/division
  /// 3. Between two non-base currencies: converts through base currency
  ///
  /// Returns the original [amount] if either currency rate is not found.
  double convert(String from, String to, double amount) {
    if (from == to) return amount;

    if (from == baseCurrency) {
      final toRate = rates[to];
      if (toRate == null) return amount;
      return amount * toRate;
    }

    if (to == baseCurrency) {
      final fromRate = rates[from];
      if (fromRate == null) return amount;
      return amount / fromRate;
    }

    final fromRate = rates[from];
    final toRate = rates[to];
    if (fromRate == null || toRate == null) return amount;

    return (amount / fromRate) * toRate;
  }

  Map<String, dynamic> toJson() => {
        'baseCurrency': baseCurrency,
        'rates': rates,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory ExchangeRate.fromJson(Map<String, dynamic> json) => ExchangeRate(
        baseCurrency: json['baseCurrency'] as String,
        rates: Map<String, double>.from(json['rates'] as Map),
        lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      );
}
