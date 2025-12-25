import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// Reusable dashboard app bar with tab switcher and action buttons
class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final AppTheme appTheme;
  final int currentIndex;
  final List<String> tabs;
  final Function(int) onTabChanged;
  final VoidCallback onRefresh;
  final VoidCallback onSettings;

  const DashboardAppBar({
    super.key,
    required this.appTheme,
    required this.currentIndex,
    required this.tabs,
    required this.onTabChanged,
    required this.onRefresh,
    required this.onSettings,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: appTheme.background,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: false,
      title: Row(
        children: List.generate(
          tabs.length,
          (index) => Padding(
            padding: EdgeInsets.only(right: index < tabs.length - 1 ? 24 : 0),
            child: _TabButton(
              label: tabs[index],
              isSelected: currentIndex == index,
              appTheme: appTheme,
              onTap: () {
                if (index != currentIndex) {
                  HapticFeedback.selectionClick();
                  onTabChanged(index);
                }
              },
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: appTheme.textPrimary),
          onPressed: () {
            HapticFeedback.lightImpact();
            onRefresh();
          },
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: Icon(Icons.settings, color: appTheme.textPrimary),
          onPressed: () {
            HapticFeedback.lightImpact();
            onSettings();
          },
          tooltip: 'Settings',
        ),
      ],
    );
  }
}

/// Tab button widget with animation
class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final AppTheme appTheme;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.appTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        style: TextStyle(
          color: isSelected ? appTheme.accent : appTheme.textTertiary,
          fontSize: isSelected ? 20 : 18,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
        child: Text(label),
      ),
    );
  }
}
