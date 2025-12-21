import '../../config/env_config.dart';

/// Interface for configuration service
abstract class IConfigService {
  String getPrivacyPolicyURL();
  String getTermsAndConditionsURL();
  int getSpecialOfferFrequencyInDays();
}

/// Implementation of config service
/// Use getIt<ConfigService>() to access the singleton instance
class ConfigService implements IConfigService {
  @override
  String getPrivacyPolicyURL() {
    return EnvConfig.privacyPolicyUrl;
  }

  @override
  String getTermsAndConditionsURL() {
    return EnvConfig.termsAndConditionsUrl;
  }

  @override
  int getSpecialOfferFrequencyInDays() {
    return 7; // Default to weekly
  }
}
