import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Settings dialog showing data status and options
class SettingsDialog extends StatelessWidget {
  final bool fromCache;
  final String nextUpdate;
  final DateTime? lastUpdate;
  final int currencyCount;
  final VoidCallback onForceRefresh;
  final AppTheme appTheme;

  const SettingsDialog({
    super.key,
    required this.fromCache,
    required this.nextUpdate,
    required this.lastUpdate,
    required this.currencyCount,
    required this.onForceRefresh,
    required this.appTheme,
  });

  static Future<void> show({
    required BuildContext context,
    required bool fromCache,
    required String nextUpdate,
    required DateTime? lastUpdate,
    required int currencyCount,
    required VoidCallback onForceRefresh,
    required AppTheme appTheme,
  }) {
    return showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        fromCache: fromCache,
        nextUpdate: nextUpdate,
        lastUpdate: lastUpdate,
        currencyCount: currencyCount,
        onForceRefresh: onForceRefresh,
        appTheme: appTheme,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: appTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Data Settings',
        style:
            TextStyle(color: appTheme.textPrimary, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: fromCache
                  ? Colors.orange.withOpacity(0.2)
                  : Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  fromCache ? Icons.storage : Icons.cloud_done,
                  color: fromCache ? Colors.orange : Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fromCache ? 'Using Cached Data' : 'Live Data',
                        style: TextStyle(
                          color: fromCache ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        fromCache
                            ? 'Next update: $nextUpdate'
                            : 'Data is up to date',
                        style: TextStyle(
                          color: appTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'The app fetches data from API twice per day (every 12 hours) and stores it locally.',
            style: TextStyle(color: appTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (lastUpdate != null) ...[
            _buildInfoRow('Last Update', _formatDateTime(lastUpdate!)),
            const SizedBox(height: 8),
          ],
          _buildInfoRow('Currencies', '$currencyCount'),
          const SizedBox(height: 24),
          // Theme selector section
          Text(
            'Appearance',
            style: TextStyle(
              color: appTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _buildThemeOption(
            'Blue Theme',
            'Dark blue with navy backgrounds',
            ThemeOption.blue,
          ),
          const SizedBox(height: 8),
          _buildThemeOption(
            'Dark Theme',
            'Pure black OLED-friendly',
            ThemeOption.dark,
          ),
          const SizedBox(height: 8),
          _buildThemeOption(
            'Light Theme',
            'Clean white backgrounds',
            ThemeOption.light,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onForceRefresh();
          },
          child: Text(
            'Force Refresh',
            style:
                TextStyle(color: appTheme.primary, fontWeight: FontWeight.w600),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Close',
            style: TextStyle(color: appTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption(String title, String subtitle, ThemeOption theme) {
    final isSelected = appTheme.currentTheme == theme;
    return InkWell(
      onTap: () => appTheme.setTheme(theme),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? appTheme.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? appTheme.primary : appTheme.surfaceLight,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? appTheme.primary : appTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? appTheme.textPrimary
                          : appTheme.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: appTheme.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: appTheme.textTertiary, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: appTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$hour:$minute ($day/$month)';
  }
}
