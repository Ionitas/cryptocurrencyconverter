import 'package:flutter/material.dart';

/// App-wide color constants for consistent theming
abstract class AppColors {
  // Background colors
  static const Color background = Color(0xFF1A1F2E);
  static const Color surface = Color(0xFF252B3D);
  static const Color surfaceLight = Color(0xFF374151);

  // Primary colors
  static const Color primary = Color(0xFF3B7FFF);
  static const Color primaryLight = Color(0xFF4B5563);

  // Accent colors
  static const Color accent = Color(0xFFFF9500);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFEF4444);

  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textTertiary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFFE5E7EB);

  // Crypto/Fiat indicator colors
  static const Color cryptoBackground = Color(0x33FF9500);
  static const Color fiatBackground = Color(0x333B7FFF);
}

/// Blue theme - Apple-style dark blue theme (default)
abstract class AppColorsBlue {
  // Background colors
  static const Color background = Color(0xFF1A1F2E);
  static const Color surface = Color(0xFF252B3D);
  static const Color surfaceLight = Color(0xFF374151);

  // Primary colors
  static const Color primary = Color(0xFF3B7FFF);
  static const Color primaryLight = Color(0xFF4B5563);

  // Accent colors
  static const Color accent = Color(0xFFFF9500);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFEF4444);

  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textTertiary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFFE5E7EB);

  // Crypto/Fiat indicator colors
  static const Color cryptoBackground = Color(0x33FF9500);
  static const Color fiatBackground = Color(0x333B7FFF);
}

/// Dark theme - Pure black OLED-friendly theme
abstract class AppColorsDark {
  // Background colors
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF1C1C1E);
  static const Color surfaceLight = Color(0xFF2C2C2E);

  // Primary colors
  static const Color primary = Color(0xFF0A84FF);
  static const Color primaryLight = Color(0xFF3A3A3C);

  // Accent colors
  static const Color accent = Color(0xFFFF9F0A);
  static const Color success = Color(0xFF32D74B);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color error = Color(0xFFFF453A);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF98989D);
  static const Color textTertiary = Color(0xFF636366);
  static const Color textLight = Color(0xFFEBEBF5);

  // Crypto/Fiat indicator colors
  static const Color cryptoBackground = Color(0x33FF9F0A);
  static const Color fiatBackground = Color(0x330A84FF);
}

/// Light theme - Clean white Apple-style theme
abstract class AppColorsLight {
  // Background colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF2F2F7);
  static const Color surfaceLight = Color(0xFFE5E5EA);

  // Primary colors
  static const Color primary = Color(0xFF007AFF);
  static const Color primaryLight = Color(0xFFC7C7CC);

  // Accent colors
  static const Color accent = Color(0xFFFF9500);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);

  // Text colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF3C3C43);
  static const Color textTertiary = Color(0xFF8E8E93);
  static const Color textLight = Color(0xFF636366);

  // Crypto/Fiat indicator colors
  static const Color cryptoBackground = Color(0x33FF9500);
  static const Color fiatBackground = Color(0x33007AFF);
}
