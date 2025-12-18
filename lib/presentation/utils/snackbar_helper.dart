import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Snackbar type for theming
enum SnackBarType { success, warning, error, info }

/// Helper class for showing themed SnackBars with Liquid Glass effect
class SnackBarHelper {
  /// Show a themed SnackBar at the top of the screen with glass effect
  static void show({
    required BuildContext context,
    required String message,
    required AppTheme appTheme,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    // Skip if notifications are disabled
    if (!appTheme.showNotifications) return;

    final overlay = Overlay.of(context);
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _TopSnackBar(
        message: message,
        type: type,
        appTheme: appTheme,
        topPadding: topPadding,
        duration: duration,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);
  }

  static Color getBackgroundColor(SnackBarType type, AppTheme appTheme) {
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
}

class _TopSnackBar extends StatefulWidget {
  final String message;
  final SnackBarType type;
  final AppTheme appTheme;
  final double topPadding;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopSnackBar({
    required this.message,
    required this.type,
    required this.appTheme,
    required this.topPadding,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopSnackBar> createState() => _TopSnackBarState();
}

class _TopSnackBarState extends State<_TopSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        SnackBarHelper.getBackgroundColor(widget.type, widget.appTheme);

    return Positioned(
      top: widget.topPadding + 8,
      left: 16,
      right: 16,
      child: Material(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! < 0) {
                  _controller.reverse().then((_) => widget.onDismiss());
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: backgroundColor.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: backgroundColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getIcon(),
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (widget.type) {
      case SnackBarType.success:
        return Icons.check_circle_outline;
      case SnackBarType.warning:
        return Icons.warning_amber_rounded;
      case SnackBarType.error:
        return Icons.error_outline;
      case SnackBarType.info:
        return Icons.info_outline;
    }
  }
}
