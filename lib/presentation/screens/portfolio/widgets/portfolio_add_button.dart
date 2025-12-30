import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';

/// Bottom add button for adding new currencies
class PortfolioAddButton extends StatelessWidget {
  final AppTheme appTheme;
  final VoidCallback onTap;

  const PortfolioAddButton({
    super.key,
    required this.appTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = DesignTokens.getScreenPaddingH(context);

    return Container(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        top: DesignTokens.spaceM,
        bottom: DesignTokens.spaceXXL,
      ),
      decoration: BoxDecoration(
        color: appTheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusXXXL),
        ),
        boxShadow: DesignTokens.bottomBarShadow(),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.buttonPaddingH,
            vertical: DesignTokens.buttonPaddingV,
          ),
          decoration: BoxDecoration(
            color: appTheme.background,
            borderRadius: BorderRadius.circular(DesignTokens.radius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: appTheme.primary, size: DesignTokens.icon),
              SizedBox(width: DesignTokens.spaceS),
              Text(
                'Add Asset',
                style: TextStyle(
                  color: appTheme.primary,
                  fontSize: DesignTokens.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
