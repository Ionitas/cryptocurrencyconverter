import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../domain/models/currency.dart';

/// Data source for fetching fiat currency data from external APIs
class FiatApiDataSource {
  /// Complete mapping of currency codes to names
  static const Map<String, String> _fiatNames = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'CHF': 'Swiss Franc',
    'AUD': 'Australian Dollar',
    'CAD': 'Canadian Dollar',
    'CNY': 'Chinese Yuan',
    'HKD': 'Hong Kong Dollar',
    'NZD': 'New Zealand Dollar',
    'SEK': 'Swedish Krona',
    'KRW': 'South Korean Won',
    'SGD': 'Singapore Dollar',
    'NOK': 'Norwegian Krone',
    'MXN': 'Mexican Peso',
    'INR': 'Indian Rupee',
    'RUB': 'Russian Ruble',
    'ZAR': 'South African Rand',
    'TRY': 'Turkish Lira',
    'BRL': 'Brazilian Real',
    'TWD': 'Taiwan Dollar',
    'DKK': 'Danish Krone',
    'PLN': 'Polish Zloty',
    'THB': 'Thai Baht',
    'IDR': 'Indonesian Rupiah',
    'HUF': 'Hungarian Forint',
    'CZK': 'Czech Koruna',
    'ILS': 'Israeli Shekel',
    'CLP': 'Chilean Peso',
    'PHP': 'Philippine Peso',
    'AED': 'UAE Dirham',
    'COP': 'Colombian Peso',
    'SAR': 'Saudi Riyal',
    'MYR': 'Malaysian Ringgit',
    'RON': 'Romanian Leu',
    'ARS': 'Argentine Peso',
    'BGN': 'Bulgarian Lev',
    'HRK': 'Croatian Kuna',
    'PEN': 'Peruvian Sol',
    'UAH': 'Ukrainian Hryvnia',
    'EGP': 'Egyptian Pound',
    'PKR': 'Pakistani Rupee',
    'VND': 'Vietnamese Dong',
    'BDT': 'Bangladeshi Taka',
    'NGN': 'Nigerian Naira',
    'KES': 'Kenyan Shilling',
    'QAR': 'Qatari Rial',
    'KWD': 'Kuwaiti Dinar',
    'MAD': 'Moroccan Dirham',
    'OMR': 'Omani Rial',
    'BHD': 'Bahraini Dinar',
    'JOD': 'Jordanian Dinar',
    'LKR': 'Sri Lankan Rupee',
    'MMK': 'Myanmar Kyat',
    'NPR': 'Nepalese Rupee',
    'GHS': 'Ghanaian Cedi',
    'TZS': 'Tanzanian Shilling',
    'UGX': 'Ugandan Shilling',
    'DZD': 'Algerian Dinar',
    'IQD': 'Iraqi Dinar',
    'AFN': 'Afghan Afghani',
    'ALL': 'Albanian Lek',
    'AMD': 'Armenian Dram',
    'AZN': 'Azerbaijani Manat',
    'BAM': 'Bosnia Mark',
    'BBD': 'Barbadian Dollar',
    'BND': 'Brunei Dollar',
    'BOB': 'Bolivian Boliviano',
    'BWP': 'Botswanan Pula',
    'BYN': 'Belarusian Ruble',
    'CRC': 'Costa Rican Colón',
    'DOP': 'Dominican Peso',
    'ETB': 'Ethiopian Birr',
    'FJD': 'Fijian Dollar',
    'GEL': 'Georgian Lari',
    'GTQ': 'Guatemalan Quetzal',
    'HNL': 'Honduran Lempira',
    'ISK': 'Icelandic Króna',
    'JMD': 'Jamaican Dollar',
    'KGS': 'Kyrgystani Som',
    'KHR': 'Cambodian Riel',
    'KZT': 'Kazakhstani Tenge',
    'LAK': 'Laotian Kip',
    'LBP': 'Lebanese Pound',
    'MDL': 'Moldovan Leu',
    'MKD': 'Macedonian Denar',
    'MNT': 'Mongolian Tugrik',
    'MUR': 'Mauritian Rupee',
    'NAD': 'Namibian Dollar',
    'NIO': 'Nicaraguan Córdoba',
    'PAB': 'Panamanian Balboa',
    'PYG': 'Paraguayan Guarani',
    'RSD': 'Serbian Dinar',
    'RWF': 'Rwandan Franc',
    'SDG': 'Sudanese Pound',
    'TJS': 'Tajikistani Somoni',
    'TND': 'Tunisian Dinar',
    'TTD': 'Trinidad Dollar',
    'UYU': 'Uruguayan Peso',
    'UZS': 'Uzbekistan Som',
    'VES': 'Venezuelan Bolívar',
    'XAF': 'Central African CFA',
    'XOF': 'West African CFA',
    'YER': 'Yemeni Rial',
    'ZMW': 'Zambian Kwacha',
  };

  /// Fetches fiat currencies from ExchangeRate API
  /// Falls back to hardcoded data if API fails
  Future<List<Currency>> fetchFiatCurrencies() async {
    try {
      final response = await http
          .get(Uri.parse('${AppConstants.exchangeRateBaseUrl}/USD'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final Map<String, dynamic> rates = data['rates'] ?? {};

        final List<Currency> currencies = [];
        for (final entry in _fiatNames.entries) {
          if (rates.containsKey(entry.key)) {
            final rate = (rates[entry.key] ?? 1.0).toDouble();
            currencies.add(Currency.fromExchangeRate(
              entry.key,
              entry.value,
              1.0 / rate,
            ));
          }
        }
        return currencies;
      }
    } catch (e) {
      print('ExchangeRate API error: $e');
    }

    return _getFallbackFiat();
  }

  List<Currency> _getFallbackFiat() {
    const fiatData = [
      {'code': 'USD', 'name': 'US Dollar', 'rate': 1.0},
      {'code': 'EUR', 'name': 'Euro', 'rate': 1.08},
      {'code': 'GBP', 'name': 'British Pound', 'rate': 1.27},
      {'code': 'JPY', 'name': 'Japanese Yen', 'rate': 0.0067},
      {'code': 'CHF', 'name': 'Swiss Franc', 'rate': 1.14},
      {'code': 'AUD', 'name': 'Australian Dollar', 'rate': 0.65},
      {'code': 'CAD', 'name': 'Canadian Dollar', 'rate': 0.74},
      {'code': 'CNY', 'name': 'Chinese Yuan', 'rate': 0.14},
      {'code': 'INR', 'name': 'Indian Rupee', 'rate': 0.012},
      {'code': 'RUB', 'name': 'Russian Ruble', 'rate': 0.011},
      {'code': 'BRL', 'name': 'Brazilian Real', 'rate': 0.20},
      {'code': 'MXN', 'name': 'Mexican Peso', 'rate': 0.058},
      {'code': 'KRW', 'name': 'South Korean Won', 'rate': 0.00077},
      {'code': 'SGD', 'name': 'Singapore Dollar', 'rate': 0.74},
      {'code': 'HKD', 'name': 'Hong Kong Dollar', 'rate': 0.13},
      {'code': 'PLN', 'name': 'Polish Zloty', 'rate': 0.25},
      {'code': 'TRY', 'name': 'Turkish Lira', 'rate': 0.034},
      {'code': 'ZAR', 'name': 'South African Rand', 'rate': 0.055},
      {'code': 'AED', 'name': 'UAE Dirham', 'rate': 0.27},
      {'code': 'SAR', 'name': 'Saudi Riyal', 'rate': 0.27},
      {'code': 'MDL', 'name': 'Moldovan Leu', 'rate': 0.056},
    ];

    return fiatData
        .map((f) => Currency(
              id: (f['code'] as String).toLowerCase(),
              code: f['code'] as String,
              symbol: f['code'] as String,
              name: f['name'] as String,
              priceUsd: f['rate'] as double,
              changePercent24h: 0.0,
              isCrypto: false,
              lastUpdated: DateTime.now(),
            ))
        .toList();
  }
}
