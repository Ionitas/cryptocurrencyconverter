import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/theme_service.dart';

/// Available theme options
enum ThemeOption { blue, dark, light }

/// Provides theme colors and manages theme changes
class AppTheme extends ChangeNotifier {
  ThemeOption _currentTheme = ThemeOption.blue;
  final ThemeService _themeService = ThemeService();

  AppTheme() {
    _loadTheme();
  }

  ThemeOption get currentTheme => _currentTheme;

  /// Load saved theme from storage
  Future<void> _loadTheme() async {
    final themeName = await _themeService.loadTheme();
    _currentTheme = _themeNameToEnum(themeName);
    notifyListeners();
  }

  /// Change theme and save to storage
  Future<void> setTheme(ThemeOption theme) async {
    _currentTheme = theme;
    await _themeService.saveTheme(_enumToThemeName(theme));
    notifyListeners();
  }

  // Color getters based on current theme
  Color get background => _getColor('background');
  Color get surface => _getColor('surface');
  Color get surfaceLight => _getColor('surfaceLight');
  Color get primary => _getColor('primary');
  Color get primaryLight => _getColor('primaryLight');
  Color get accent => _getColor('accent');
  Color get success => _getColor('success');
  Color get error => _getColor('error');
  Color get textPrimary => _getColor('textPrimary');
  Color get textSecondary => _getColor('textSecondary');
  Color get textTertiary => _getColor('textTertiary');
  Color get textLight => _getColor('textLight');
  Color get cryptoBackground => _getColor('cryptoBackground');
  Color get fiatBackground => _getColor('fiatBackground');

  /// Get color value based on current theme
  Color _getColor(String colorName) {
    switch (_currentTheme) {
      case ThemeOption.blue:
        return _getBlueColor(colorName);
      case ThemeOption.dark:
        return _getDarkColor(colorName);
      case ThemeOption.light:
        return _getLightColor(colorName);
    }
  }

  Color _getBlueColor(String name) {
    switch (name) {
      case 'background':
        return AppColorsBlue.background;
      case 'surface':
        return AppColorsBlue.surface;
      case 'surfaceLight':
        return AppColorsBlue.surfaceLight;
      case 'primary':
        return AppColorsBlue.primary;
      case 'primaryLight':
        return AppColorsBlue.primaryLight;
      case 'accent':
        return AppColorsBlue.accent;
      case 'success':
        return AppColorsBlue.success;
      case 'error':
        return AppColorsBlue.error;
      case 'textPrimary':
        return AppColorsBlue.textPrimary;
      case 'textSecondary':
        return AppColorsBlue.textSecondary;
      case 'textTertiary':
        return AppColorsBlue.textTertiary;
      case 'textLight':
        return AppColorsBlue.textLight;
      case 'cryptoBackground':
        return AppColorsBlue.cryptoBackground;
      case 'fiatBackground':
        return AppColorsBlue.fiatBackground;
      default:
        return Colors.white;
    }
  }

  Color _getDarkColor(String name) {
    switch (name) {
      case 'background':
        return AppColorsDark.background;
      case 'surface':
        return AppColorsDark.surface;
      case 'surfaceLight':
        return AppColorsDark.surfaceLight;
      case 'primary':
        return AppColorsDark.primary;
      case 'primaryLight':
        return AppColorsDark.primaryLight;
      case 'accent':
        return AppColorsDark.accent;
      case 'success':
        return AppColorsDark.success;
      case 'error':
        return AppColorsDark.error;
      case 'textPrimary':
        return AppColorsDark.textPrimary;
      case 'textSecondary':
        return AppColorsDark.textSecondary;
      case 'textTertiary':
        return AppColorsDark.textTertiary;
      case 'textLight':
        return AppColorsDark.textLight;
      case 'cryptoBackground':
        return AppColorsDark.cryptoBackground;
      case 'fiatBackground':
        return AppColorsDark.fiatBackground;
      default:
        return Colors.white;
    }
  }

  Color _getLightColor(String name) {
    switch (name) {
      case 'background':
        return AppColorsLight.background;
      case 'surface':
        return AppColorsLight.surface;
      case 'surfaceLight':
        return AppColorsLight.surfaceLight;
      case 'primary':
        return AppColorsLight.primary;
      case 'primaryLight':
        return AppColorsLight.primaryLight;
      case 'accent':
        return AppColorsLight.accent;
      case 'success':
        return AppColorsLight.success;
      case 'error':
        return AppColorsLight.error;
      case 'textPrimary':
        return AppColorsLight.textPrimary;
      case 'textSecondary':
        return AppColorsLight.textSecondary;
      case 'textTertiary':
        return AppColorsLight.textTertiary;
      case 'textLight':
        return AppColorsLight.textLight;
      case 'cryptoBackground':
        return AppColorsLight.cryptoBackground;
      case 'fiatBackground':
        return AppColorsLight.fiatBackground;
      default:
        return Colors.black;
    }
  }

  ThemeOption _themeNameToEnum(String name) {
    switch (name) {
      case 'dark':
        return ThemeOption.dark;
      case 'light':
        return ThemeOption.light;
      default:
        return ThemeOption.blue;
    }
  }

  String _enumToThemeName(ThemeOption theme) {
    switch (theme) {
      case ThemeOption.blue:
        return 'blue';
      case ThemeOption.dark:
        return 'dark';
      case ThemeOption.light:
        return 'light';
    }
  }
}
