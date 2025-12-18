import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Snackbar type for theming
enum SnackBarType { success, warning, error, info }

/// Helper class for showing themed SnackBars
class SnackBarHelper {
  /// Show a themed SnackBar with optional floating behavior
  static void show({
    required BuildContext context,
    required String message,
    required AppTheme appTheme,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    // Skip if notifications are disabled
    if (!appTheme.showNotifications) return;

    final backgroundColor = _getBackgroundColor(type, appTheme);
    final textColor = _getTextColor(type, appTheme);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  static Color _getBackgroundColor(SnackBarType type, AppTheme appTheme) {
    switch (type) {
      case SnackBarType.success:
        return appTheme.success;
      case SnackBarType.warning:
        return appTheme.warning;
      case SnackBarType.error:
        return appTheme.error;
      case SnackBarType.info:
        return appTheme.primary;
    }
  }

  static Color _getTextColor(SnackBarType type, AppTheme appTheme) {
    // For light theme, use white text on colored backgrounds
    // For other themes, also use white for contrast
    return Colors.white;
  }
}
