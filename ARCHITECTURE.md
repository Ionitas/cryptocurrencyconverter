# Clean Architecture Overview

## Project Structure

```
lib/
├── core/                           # Core application infrastructure
│   ├── constants/
│   │   └── app_constants.dart     # API URLs, cache settings, limits
│   └── di/
│       └── injection.dart         # GetIt dependency injection setup
│
├── domain/                         # Business logic layer
│   ├── models/
│   │   └── currency.dart          # Currency domain model (100+ flags, 70+ crypto icons)
│   └── repositories/
│       └── currency_repository.dart  # Abstract repository interface
│
├── data/                          # Data access layer
│   ├── datasources/
│   │   ├── crypto_api_datasource.dart    # CoinCap API (primary), CoinGecko (fallback)
│   │   ├── fiat_api_datasource.dart      # ExchangeRate API (60+ fiat currencies)
│   │   └── local_cache_datasource.dart   # SharedPreferences caching (12h validity)
│   └── repositories/
│       └── currency_repository_impl.dart  # Repository implementation
│
├── presentation/                  # UI layer
│   └── screens/
│       └── converter_screen.dart  # Main currency converter UI
│
└── main.dart                      # Application entry point
```

## Architecture Principles

### 1. Clean Architecture
- **Domain Layer**: Contains business logic and entities
  - Models: Pure Dart classes with no dependencies
  - Repositories: Abstract interfaces defining contracts
  
- **Data Layer**: Implements data access
  - Data Sources: Handle external APIs and local cache
  - Repository Implementations: Concrete implementations of domain contracts
  
- **Presentation Layer**: UI components
  - Screens: Stateful widgets that consume repository data

### 2. Dependency Injection
- Uses **GetIt** for service locator pattern
- All dependencies registered in `injection.dart`
- No Riverpod (removed for simplicity)

### 3. Data Flow
```
UI (converter_screen.dart)
  ↓ calls
Repository Interface (currency_repository.dart)
  ↓ implemented by
Repository Implementation (currency_repository_impl.dart)
  ↓ uses
Data Sources (crypto_api, fiat_api, local_cache)
  ↓ fetches from
APIs / Cache
```

## Key Features

### Multi-Tier Data Fetching
1. **Cache First**: Check if data is valid (< 12 hours old)
2. **API Fallback**: CoinCap API → CoinGecko API → Hardcoded fallback
3. **Caching**: Save fetched data for offline access

### Currency Support
- **Fiat**: 60+ major world currencies with country flags
- **Crypto**: 100 cryptocurrencies (free), 250+ (premium)
- **Icons**: Emoji-based flags and crypto icons

### Conversion Logic
- Real-time conversion via USD base rates
- Formula: `amount * (toCurrency.price / fromCurrency.price)`
- Premium features for expanded currency lists

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  get_it: ^7.6.0                  # Dependency injection
  http: ^1.6.0                    # API calls
  shared_preferences: ^2.5.3      # Local caching
  sqflite: ^2.3.0                 # SQLite (optional)
  window_manager: ^0.4.3          # Desktop window control
```

## Removed Dependencies
- ❌ `flutter_riverpod`: Replaced with GetIt
- ❌ `hive`: Using SharedPreferences instead
- ❌ `path_provider`, `connectivity_plus`: Unnecessary
- ❌ Old service layer (`/lib/services/`)

## API Endpoints

1. **CoinCap API** (Primary Crypto)
   - URL: `https://api.coincap.com/v2/assets`
   - Limit: 100 cryptocurrencies (free)

2. **CoinGecko API** (Fallback Crypto)
   - URL: `https://api.coingecko.com/api/v3/coins/markets`
   - Limit: 100 cryptocurrencies

3. **ExchangeRate API** (Fiat)
   - URL: `https://api.exchangerate-api.com/v4/latest/USD`
   - Coverage: 60+ world currencies

## Cache Strategy
- **Validity**: 12 hours
- **Storage**: SharedPreferences (JSON serialization)
- **Keys**: `cached_currencies`, `last_update_time`, `is_premium`

## Testing Notes
- Run `flutter pub get` after checkout
- Desktop app optimized for macOS (window_manager)
- Network entitlements configured for API calls
- Fallback data ensures offline functionality

## Next Steps for Development
- Add unit tests for repository layer
- Implement proper error handling with custom exceptions
- Add loading states and better error messages
- Consider adding analytics/logging
- Optimize currency icon loading
