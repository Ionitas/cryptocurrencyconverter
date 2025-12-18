import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting and loading theme preferences
class ThemeService {
  static const String _themeKey = 'app_theme';

  /// Save selected theme to local storage
  Future<void> saveTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeName);
  }

  /// Load saved theme from local storage
  /// Returns 'blue' as default if no theme is saved
  Future<String> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'blue';
  }
}
