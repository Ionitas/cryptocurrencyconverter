import 'package:flutter/material.dart';

/// Call-to-Action button widget
class CTAButton extends StatelessWidget {
  const CTAButton({
    super.key,
    required this.buttonText,
    required this.onPressed,
    this.inactive = false,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.showArrow = true,
  });

  final String buttonText;
  final VoidCallback onPressed;
  final bool inactive;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: inactive
            ? null
            : const LinearGradient(
                colors: [
                  Color(0xFF7B68EE),
                  Color(0xFF6A5ACD),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: inactive ? Colors.grey : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: inactive
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF7B68EE).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: inactive ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: textColor ?? Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (showArrow) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      color: textColor ?? Colors.white,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
