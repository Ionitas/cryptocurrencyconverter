import 'dart:convert';
import 'package:http/http.dart' as http;

/// Country data model
class CountryInfo {
  final String name;
  final String code;
  final String flag;

  const CountryInfo({
    required this.name,
    required this.code,
    required this.flag,
  });
}

/// Service for IP-based geolocation
class GeoLocationService {
  /// Popular countries list with flags
  static const List<CountryInfo> popularCountries = [
    CountryInfo(name: 'United States', code: 'US', flag: '🇺🇸'),
    CountryInfo(name: 'United Kingdom', code: 'GB', flag: '🇬🇧'),
    CountryInfo(name: 'Germany', code: 'DE', flag: '🇩🇪'),
    CountryInfo(name: 'France', code: 'FR', flag: '🇫🇷'),
    CountryInfo(name: 'Japan', code: 'JP', flag: '🇯🇵'),
    CountryInfo(name: 'China', code: 'CN', flag: '🇨🇳'),
    CountryInfo(name: 'Canada', code: 'CA', flag: '🇨🇦'),
    CountryInfo(name: 'Australia', code: 'AU', flag: '🇦🇺'),
    CountryInfo(name: 'India', code: 'IN', flag: '🇮🇳'),
    CountryInfo(name: 'Brazil', code: 'BR', flag: '🇧🇷'),
    CountryInfo(name: 'Spain', code: 'ES', flag: '🇪🇸'),
    CountryInfo(name: 'Italy', code: 'IT', flag: '🇮🇹'),
    CountryInfo(name: 'Netherlands', code: 'NL', flag: '🇳🇱'),
    CountryInfo(name: 'Switzerland', code: 'CH', flag: '🇨🇭'),
    CountryInfo(name: 'Singapore', code: 'SG', flag: '🇸🇬'),
    CountryInfo(name: 'South Korea', code: 'KR', flag: '🇰🇷'),
    CountryInfo(name: 'Mexico', code: 'MX', flag: '🇲🇽'),
    CountryInfo(name: 'Russia', code: 'RU', flag: '🇷🇺'),
    CountryInfo(name: 'Turkey', code: 'TR', flag: '🇹🇷'),
    CountryInfo(name: 'Poland', code: 'PL', flag: '🇵🇱'),
    CountryInfo(name: 'Sweden', code: 'SE', flag: '🇸🇪'),
    CountryInfo(name: 'Norway', code: 'NO', flag: '🇳🇴'),
    CountryInfo(name: 'Denmark', code: 'DK', flag: '🇩🇰'),
    CountryInfo(name: 'Austria', code: 'AT', flag: '🇦🇹'),
    CountryInfo(name: 'Belgium', code: 'BE', flag: '🇧🇪'),
    CountryInfo(name: 'Portugal', code: 'PT', flag: '🇵🇹'),
    CountryInfo(name: 'Ireland', code: 'IE', flag: '🇮🇪'),
    CountryInfo(name: 'New Zealand', code: 'NZ', flag: '🇳🇿'),
    CountryInfo(name: 'Argentina', code: 'AR', flag: '🇦🇷'),
    CountryInfo(name: 'Chile', code: 'CL', flag: '🇨🇱'),
    CountryInfo(name: 'Colombia', code: 'CO', flag: '🇨🇴'),
    CountryInfo(name: 'South Africa', code: 'ZA', flag: '🇿🇦'),
    CountryInfo(name: 'United Arab Emirates', code: 'AE', flag: '🇦🇪'),
    CountryInfo(name: 'Saudi Arabia', code: 'SA', flag: '🇸🇦'),
    CountryInfo(name: 'Israel', code: 'IL', flag: '🇮🇱'),
    CountryInfo(name: 'Thailand', code: 'TH', flag: '🇹🇭'),
    CountryInfo(name: 'Vietnam', code: 'VN', flag: '🇻🇳'),
    CountryInfo(name: 'Indonesia', code: 'ID', flag: '🇮🇩'),
    CountryInfo(name: 'Malaysia', code: 'MY', flag: '🇲🇾'),
    CountryInfo(name: 'Philippines', code: 'PH', flag: '🇵🇭'),
    CountryInfo(name: 'Romania', code: 'RO', flag: '🇷🇴'),
    CountryInfo(name: 'Czech Republic', code: 'CZ', flag: '🇨🇿'),
    CountryInfo(name: 'Hungary', code: 'HU', flag: '🇭🇺'),
    CountryInfo(name: 'Greece', code: 'GR', flag: '🇬🇷'),
    CountryInfo(name: 'Finland', code: 'FI', flag: '🇫🇮'),
    CountryInfo(name: 'Ukraine', code: 'UA', flag: '🇺🇦'),
    CountryInfo(name: 'Egypt', code: 'EG', flag: '🇪🇬'),
    CountryInfo(name: 'Nigeria', code: 'NG', flag: '🇳🇬'),
    CountryInfo(name: 'Pakistan', code: 'PK', flag: '🇵🇰'),
    CountryInfo(name: 'Bangladesh', code: 'BD', flag: '🇧🇩'),
  ];

  /// Detect country from IP address
  Future<CountryInfo?> detectCountryFromIP() async {
    try {
      // Using ip-api.com (free, no API key required)
      final response =
          await http.get(Uri.parse('http://ip-api.com/json')).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final countryCode = data['countryCode'] as String?;
        final countryName = data['country'] as String?;

        if (countryCode != null && countryName != null) {
          // Try to find in our list first (for flag)
          final found = popularCountries.where(
            (c) => c.code == countryCode,
          );

          if (found.isNotEmpty) {
            return found.first;
          }

          // Return with generic flag if not in list
          return CountryInfo(
            name: countryName,
            code: countryCode,
            flag: _getFlagEmoji(countryCode),
          );
        }
      }
    } catch (e) {
      // Silently fail, will use default
    }

    return null;
  }

  /// Convert country code to flag emoji
  String _getFlagEmoji(String countryCode) {
    final int firstLetter = countryCode.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter = countryCode.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }

  /// Get country by code
  CountryInfo? getCountryByCode(String code) {
    try {
      return popularCountries.firstWhere((c) => c.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Search countries by name
  List<CountryInfo> searchCountries(String query) {
    if (query.isEmpty) return popularCountries;

    final lowerQuery = query.toLowerCase();
    return popularCountries.where((c) {
      return c.name.toLowerCase().contains(lowerQuery) || c.code.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
