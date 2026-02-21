import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/services/analytics/logging_system.dart';

/// Settings dialog showing data status and options
class SettingsDialog extends StatefulWidget {
  final bool fromCache;
  final String nextUpdate;
  final DateTime? lastUpdate;
  final int currencyCount;
  final VoidCallback onForceRefresh;
  final AppTheme appTheme;
  final String? userCountry;
  final String? userCountryFlag;
  final String? userCurrencyCode;

  const SettingsDialog({
    super.key,
    required this.fromCache,
    required this.nextUpdate,
    required this.lastUpdate,
    required this.currencyCount,
    required this.onForceRefresh,
    required this.appTheme,
    this.userCountry,
    this.userCountryFlag,
    this.userCurrencyCode,
  });

  static Future<void> show({
    required BuildContext context,
    required bool fromCache,
    required String nextUpdate,
    required DateTime? lastUpdate,
    required int currencyCount,
    required VoidCallback onForceRefresh,
    required AppTheme appTheme,
    String? userCountry,
    String? userCountryFlag,
    String? userCurrencyCode,
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
        userCountry: userCountry,
        userCountryFlag: userCountryFlag,
        userCurrencyCode: userCurrencyCode,
      ),
    );
  }

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  @override
  void initState() {
    super.initState();
    widget.appTheme.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    widget.appTheme.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = widget.appTheme;

    return AlertDialog(
      backgroundColor: appTheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXXL),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: appTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: appTheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Settings',
            style: TextStyle(
              color: appTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.fromCache
                        ? [
                            appTheme.warning.withValues(alpha: 0.2),
                            appTheme.warning.withValues(alpha: 0.1),
                          ]
                        : [
                            appTheme.success.withValues(alpha: 0.2),
                            appTheme.success.withValues(alpha: 0.1),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.fromCache
                        ? appTheme.warning.withValues(alpha: 0.3)
                        : appTheme.success.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.fromCache
                            ? appTheme.warning.withValues(alpha: 0.2)
                            : appTheme.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.fromCache
                            ? Icons.storage_rounded
                            : Icons.cloud_done_rounded,
                        color: widget.fromCache
                            ? appTheme.warning
                            : appTheme.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.fromCache
                                ? 'Using Cached Data'
                                : 'Live Data',
                            style: TextStyle(
                              color: widget.fromCache
                                  ? appTheme.warning
                                  : appTheme.success,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.fromCache
                                ? 'Next update: ${widget.nextUpdate}'
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: appTheme.surfaceLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: appTheme.textTertiary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rates update every 12 hours',
                        style: TextStyle(
                            color: appTheme.textTertiary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (widget.lastUpdate != null) ...[
                _buildInfoRow(
                    'Last Update', _formatDateTime(widget.lastUpdate!)),
                const SizedBox(height: 8),
              ],
              _buildInfoRow('Currencies', '${widget.currencyCount}'),
              // User country section
              if (widget.userCountry != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow('Your Country',
                    '${widget.userCountryFlag ?? '🌍'} ${widget.userCountry}'),
                if (widget.userCurrencyCode != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Your Currency', widget.userCurrencyCode!),
                ],
              ],
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
              const SizedBox(height: 24),
              // Notifications section
              Text(
                'Notifications',
                style: TextStyle(
                  color: appTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _buildFloatingSnackBarToggle(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            AppLogger.buttonTap('Force Refresh (Settings)');
            Navigator.pop(context);
            widget.onForceRefresh();
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
    final appTheme = widget.appTheme;
    final isSelected = appTheme.currentTheme == theme;
    return InkWell(
      onTap: () => appTheme.setTheme(theme),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? appTheme.primary.withValues(alpha: 0.2)
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
    final appTheme = widget.appTheme;
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

  Widget _buildFloatingSnackBarToggle() {
    final appTheme = widget.appTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appTheme.surfaceLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: appTheme.surfaceLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            appTheme.showNotifications
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            color: appTheme.textSecondary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Show Notifications',
                  style: TextStyle(
                    color: appTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Display status messages',
                  style: TextStyle(
                    color: appTheme.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: appTheme.showNotifications,
            onChanged: (value) => appTheme.setShowNotifications(value),
            activeThumbColor: appTheme.primary,
          ),
        ],
      ),
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
