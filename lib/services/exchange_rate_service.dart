import '../models/exchange_rate.dart';

abstract class ExchangeRateService {
  Future<ExchangeRate> fetchRates();
}
