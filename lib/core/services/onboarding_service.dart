import 'package:shared_preferences/shared_preferences.dart';

/// User purpose options for the app
enum UserPurpose { financial, travel, investments, other }

/// Onboarding data model
class OnboardingData {
  final String? country;
  final String? countryCode;
  final UserPurpose? purpose;
  final bool completed;

  const OnboardingData({
    this.country,
    this.countryCode,
    this.purpose,
    this.completed = false,
  });

  OnboardingData copyWith({
    String? country,
    String? countryCode,
    UserPurpose? purpose,
    bool? completed,
  }) {
    return OnboardingData(
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      purpose: purpose ?? this.purpose,
      completed: completed ?? this.completed,
    );
  }

  /// Get the currency code for this country
  String? get currencyCode => countryToCurrency[countryCode];

  /// Map of country codes to currency codes
  static const Map<String, String> countryToCurrency = {
    'US': 'USD',
    'GB': 'GBP',
    'DE': 'EUR',
    'FR': 'EUR',
    'IT': 'EUR',
    'ES': 'EUR',
    'NL': 'EUR',
    'BE': 'EUR',
    'AT': 'EUR',
    'PT': 'EUR',
    'IE': 'EUR',
    'FI': 'EUR',
    'GR': 'EUR',
    'JP': 'JPY',
    'CN': 'CNY',
    'CA': 'CAD',
    'AU': 'AUD',
    'IN': 'INR',
    'BR': 'BRL',
    'CH': 'CHF',
    'SG': 'SGD',
    'KR': 'KRW',
    'MX': 'MXN',
    'RU': 'RUB',
    'TR': 'TRY',
    'PL': 'PLN',
    'SE': 'SEK',
    'NO': 'NOK',
    'DK': 'DKK',
    'NZ': 'NZD',
    'AR': 'ARS',
    'CL': 'CLP',
    'CO': 'COP',
    'ZA': 'ZAR',
    'AE': 'AED',
    'SA': 'SAR',
    'IL': 'ILS',
    'TH': 'THB',
    'VN': 'VND',
    'ID': 'IDR',
    'MY': 'MYR',
    'PH': 'PHP',
    'RO': 'RON',
    'CZ': 'CZK',
    'HU': 'HUF',
    'UA': 'UAH',
    'EG': 'EGP',
    'NG': 'NGN',
    'PK': 'PKR',
    'BD': 'BDT',
    // Central Asia
    'KZ': 'KZT',
    'UZ': 'UZS',
    'KG': 'KGS',
    'TJ': 'TJS',
    'TM': 'TMT',
    // More countries
    'BY': 'BYN',
    'GE': 'GEL',
    'AM': 'AMD',
    'AZ': 'AZN',
    'MD': 'MDL',
    'RS': 'RSD',
    'HR': 'HRK',
    'BG': 'BGN',
    'LT': 'EUR',
    'LV': 'EUR',
    'EE': 'EUR',
    'SK': 'EUR',
    'SI': 'EUR',
    'CY': 'EUR',
    'MT': 'EUR',
    'LU': 'EUR',
  };
}

/// Service for managing onboarding state and persistence
class OnboardingService {
  static const String _completedKey = 'onboarding_completed';
  static const String _countryKey = 'user_country';
  static const String _countryCodeKey = 'user_country_code';
  static const String _purposeKey = 'user_purpose';

  /// Check if onboarding has been completed
  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  /// Save onboarding data
  Future<void> saveOnboardingData(OnboardingData data) async {
    final prefs = await SharedPreferences.getInstance();

    if (data.country != null) {
      await prefs.setString(_countryKey, data.country!);
    }
    if (data.countryCode != null) {
      await prefs.setString(_countryCodeKey, data.countryCode!);
    }
    if (data.purpose != null) {
      await prefs.setString(_purposeKey, data.purpose!.name);
    }
    if (data.completed) {
      await prefs.setBool(_completedKey, true);
    }
  }

  /// Load saved onboarding data
  Future<OnboardingData> loadOnboardingData() async {
    final prefs = await SharedPreferences.getInstance();

    final purposeString = prefs.getString(_purposeKey);
    UserPurpose? purpose;
    if (purposeString != null) {
      purpose = UserPurpose.values.firstWhere(
        (p) => p.name == purposeString,
        orElse: () => UserPurpose.other,
      );
    }

    return OnboardingData(
      country: prefs.getString(_countryKey),
      countryCode: prefs.getString(_countryCodeKey),
      purpose: purpose,
      completed: prefs.getBool(_completedKey) ?? false,
    );
  }

  /// Reset onboarding (for testing)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedKey);
    await prefs.remove(_countryKey);
    await prefs.remove(_countryCodeKey);
    await prefs.remove(_purposeKey);
  }
}
