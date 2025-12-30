import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// Bottom bar with add currency and calculator buttons
class BottomBar extends StatelessWidget {
  final AppTheme appTheme;
  final VoidCallback onAddCurrency;
  final VoidCallback onShowCalculator;

  const BottomBar({
    super.key,
    required this.appTheme,
    required this.onAddCurrency,
    required this.onShowCalculator,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = DesignTokens.getBottomPadding(context);

    return Container(
      padding: EdgeInsets.only(
        left: DesignTokens.space,
        right: DesignTokens.space,
        top: DesignTokens.spaceM,
        bottom: bottomPadding,
      ),
      decoration: BoxDecoration(
        color: appTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusXXXL)),
        boxShadow: DesignTokens.bottomBarShadow(),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onAddCurrency,
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
                      'Add Currency',
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
          ),
          SizedBox(width: DesignTokens.spaceM),
          GestureDetector(
            onTap: onShowCalculator,
            child: Container(
              padding: EdgeInsets.all(DesignTokens.buttonPaddingV),
              decoration: BoxDecoration(
                color: appTheme.primary,
                borderRadius: BorderRadius.circular(DesignTokens.radius),
              ),
              child: Icon(Icons.calculate, color: appTheme.textPrimary, size: DesignTokens.iconL),
            ),
          ),
        ],
      ),
    );
  }
}
