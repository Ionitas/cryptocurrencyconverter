import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/services/analytics/logging_system.dart';

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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: appTheme.background,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: false,
      toolbarHeight: kToolbarHeight + 8,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: appTheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            tabs.length,
            (index) => _TabButton(
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
        _ActionButton(
          icon: Icons.refresh_rounded,
          appTheme: appTheme,
          onPressed: () {
            AppLogger.buttonTap('Refresh');
            HapticFeedback.lightImpact();
            onRefresh();
          },
          tooltip: 'Refresh rates',
        ),
        _ActionButton(
          icon: Icons.tune_rounded,
          appTheme: appTheme,
          onPressed: () {
            AppLogger.buttonTap('Settings');
            HapticFeedback.lightImpact();
            onSettings();
          },
          tooltip: 'Settings',
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Action button with subtle hover effect
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final AppTheme appTheme;
  final VoidCallback onPressed;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.appTheme,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _isPressed
                ? widget.appTheme.surfaceLight.withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Icon(
            widget.icon,
            color: widget.appTheme.textPrimary.withValues(alpha: 0.9),
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// Tab button widget with smooth animation
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? appTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: appTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : appTheme.textTertiary,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
