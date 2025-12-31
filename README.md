# CurrencyX 💱

**Real-time Cryptocurrency & Fiat Currency Converter**

A beautiful, fast, and reliable currency converter app built with Flutter. Convert between 150+ cryptocurrencies and fiat currencies with live exchange rates.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)
![License](https://img.shields.io/badge/License-Proprietary-red.svg)

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| ⚡ **Real-time Rates** | Live exchange rates from trusted APIs |
| 🌍 **150+ Currencies** | Crypto, fiat, and precious metals |
| 🧮 **Smart Calculator** | Built-in calculator for quick math |
| 📱 **Works Offline** | Cached rates for offline use |
| 📊 **Portfolio Tracking** | Track your holdings (Premium) |
| 🎨 **Beautiful Themes** | Blue, Dark, and Light modes |

---

## 🏗️ Architecture

This project follows **Clean Architecture** principles:

```
lib/
├── core/           # Theme, constants, DI, services
├── domain/         # Business logic & models
├── data/           # API datasources & repositories
└── presentation/   # UI screens & widgets
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed documentation.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Dart 3.0+
- Xcode (for iOS)
- Android Studio (for Android)

### Installation

```bash
# Clone the repository
git clone https://github.com/Ionitas/cryptocurrencyconverter.git

# Navigate to project
cd cryptocurrencyconverter

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build for Release

```bash
# iOS
flutter build ipa --release

# Android
flutter build appbundle --release

# macOS
flutter build macos --release
```

---

## 📱 Supported Platforms

- ✅ iOS 12.0+
- ✅ Android 5.0+
- ✅ macOS 10.14+

---

## 🔧 Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter 3.0+ |
| State Management | GetIt (DI) |
| Backend | Supabase |
| Payments | RevenueCat |
| Analytics | Firebase Analytics |
| Local Storage | SharedPreferences, SQLite |

---

## 📄 Documentation

- [Architecture Overview](ARCHITECTURE.md)
- [App Store Description](APP_STORE_DESCRIPTION.md)
- [Supabase Setup](supabase/SETUP_INSTRUCTIONS.md)

---

## 📝 License

This project is proprietary software. All rights reserved.

---

## 🤝 Contributing

This is a private project. Contributions are not currently accepted.

---

Made with ❤️ using Flutter
