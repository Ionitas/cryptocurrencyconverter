import 'package:flutter/material.dart';

/// Centralized design tokens for the entire app.
/// All spacing, sizing, radius, and animation values should be defined here.
/// This ensures consistency and makes global design changes easy.
abstract class DesignTokens {
  // ============================================
  // SPACING
  // ============================================

  /// Extra small spacing (4px)
  static const double spaceXS = 4.0;

  /// Small spacing (8px)
  static const double spaceS = 8.0;

  /// Medium spacing (12px)
  static const double spaceM = 12.0;

  /// Regular spacing (16px)
  static const double space = 16.0;

  /// Large spacing (20px)
  static const double spaceL = 20.0;

  /// Extra large spacing (24px)
  static const double spaceXL = 24.0;

  /// Double extra large spacing (32px)
  static const double spaceXXL = 32.0;

  /// Triple extra large spacing (40px)
  static const double spaceXXXL = 40.0;

  // ============================================
  // PADDING
  // ============================================

  /// Standard horizontal padding for screens
  static const double screenPaddingH = 16.0;

  /// Standard horizontal padding for tablets
  static const double screenPaddingHTablet = 24.0;

  /// Standard vertical padding for screens
  static const double screenPaddingV = 12.0;

  /// Card internal padding
  static const double cardPadding = 16.0;

  /// Card internal padding (large)
  static const double cardPaddingL = 20.0;

  /// Modal padding
  static const double modalPadding = 20.0;

  /// Button padding horizontal
  static const double buttonPaddingH = 16.0;

  /// Button padding vertical
  static const double buttonPaddingV = 14.0;

  /// Input field padding
  static const double inputPadding = 14.0;

  // ============================================
  // BORDER RADIUS
  // ============================================

  /// Extra small radius (8px)
  static const double radiusXS = 8.0;

  /// Small radius (10px)
  static const double radiusS = 10.0;

  /// Medium radius (12px)
  static const double radiusM = 12.0;

  /// Regular radius (14px)
  static const double radius = 14.0;

  /// Large radius (16px)
  static const double radiusL = 16.0;

  /// Extra large radius (18px)
  static const double radiusXL = 18.0;

  /// Double extra large radius (20px)
  static const double radiusXXL = 20.0;

  /// Triple extra large radius (24px)
  static const double radiusXXXL = 24.0;

  /// Full/circular radius
  static const double radiusFull = 999.0;

  // ============================================
  // ICON SIZES
  // ============================================

  /// Extra small icon (14px)
  static const double iconXS = 14.0;

  /// Small icon (16px)
  static const double iconS = 16.0;

  /// Medium icon (18px)
  static const double iconM = 18.0;

  /// Regular icon (20px)
  static const double icon = 20.0;

  /// Large icon (22px)
  static const double iconL = 22.0;

  /// Extra large icon (24px)
  static const double iconXL = 24.0;

  /// Double extra large icon (28px)
  static const double iconXXL = 28.0;

  /// Triple extra large icon (32px)
  static const double iconXXXL = 32.0;

  // ============================================
  // FONT SIZES
  // ============================================

  /// Extra small text (10px)
  static const double textXS = 10.0;

  /// Small text (11px)
  static const double textS = 11.0;

  /// Caption text (12px)
  static const double textCaption = 12.0;

  /// Body small text (13px)
  static const double textBodyS = 13.0;

  /// Body text (14px)
  static const double textBody = 14.0;

  /// Regular text (16px)
  static const double text = 16.0;

  /// Large text (18px)
  static const double textL = 18.0;

  /// Title text (20px)
  static const double textTitle = 20.0;

  /// Headline text (22px)
  static const double textHeadline = 22.0;

  /// Display small (36px)
  static const double textDisplayS = 36.0;

  /// Display (42px)
  static const double textDisplay = 42.0;

  /// Display large (52px)
  static const double textDisplayL = 52.0;

  // ============================================
  // COMPONENT SIZES
  // ============================================

  /// Currency icon size (small)
  static const double currencyIconS = 32.0;

  /// Currency icon size (default)
  static const double currencyIcon = 40.0;

  /// Currency icon size (large)
  static const double currencyIconL = 48.0;

  /// Floating action button size
  static const double fabSize = 56.0;

  /// Bottom bar height
  static const double bottomBarHeight = 80.0;

  /// App bar height
  static const double appBarHeight = 56.0;

  /// Drag handle width
  static const double dragHandleWidth = 40.0;

  /// Drag handle height
  static const double dragHandleHeight = 4.0;

  /// Card margin bottom
  static const double cardMarginBottom = 8.0;

  /// List item margin bottom
  static const double listItemMargin = 8.0;

  // ============================================
  // SHADOWS
  // ============================================

  /// Shadow blur radius (small)
  static const double shadowBlurS = 8.0;

  /// Shadow blur radius (medium)
  static const double shadowBlurM = 12.0;

  /// Shadow blur radius (large)
  static const double shadowBlurL = 16.0;

  /// Shadow blur radius (extra large)
  static const double shadowBlurXL = 20.0;

  /// Shadow offset Y (small)
  static const double shadowOffsetS = 2.0;

  /// Shadow offset Y (medium)
  static const double shadowOffsetM = 4.0;

  /// Shadow offset Y (large)
  static const double shadowOffsetL = 6.0;

  /// Shadow opacity (light)
  static const double shadowOpacityLight = 0.05;

  /// Shadow opacity (medium)
  static const double shadowOpacityMedium = 0.15;

  /// Shadow opacity (heavy)
  static const double shadowOpacityHeavy = 0.25;

  /// Shadow opacity (glow)
  static const double shadowOpacityGlow = 0.4;

  // ============================================
  // OPACITY
  // ============================================

  /// Very light opacity
  static const double opacityVeryLight = 0.08;

  /// Light opacity
  static const double opacityLight = 0.1;

  /// Medium light opacity
  static const double opacityMediumLight = 0.15;

  /// Medium opacity
  static const double opacityMedium = 0.2;

  /// Medium heavy opacity
  static const double opacityMediumHeavy = 0.3;

  /// Heavy opacity
  static const double opacityHeavy = 0.4;

  /// Very heavy opacity
  static const double opacityVeryHeavy = 0.5;

  /// High opacity
  static const double opacityHigh = 0.85;

  /// Very high opacity
  static const double opacityVeryHigh = 0.92;

  // ============================================
  // ANIMATION DURATIONS
  // ============================================

  /// Fast animation (80ms)
  static const Duration animFast = Duration(milliseconds: 80);

  /// Quick animation (100ms)
  static const Duration animQuick = Duration(milliseconds: 100);

  /// Short animation (150ms)
  static const Duration animShort = Duration(milliseconds: 150);

  /// Medium animation (200ms)
  static const Duration animMedium = Duration(milliseconds: 200);

  /// Regular animation (250ms)
  static const Duration anim = Duration(milliseconds: 250);

  /// Long animation (350ms)
  static const Duration animLong = Duration(milliseconds: 350);

  /// Slow animation (400ms)
  static const Duration animSlow = Duration(milliseconds: 400);

  /// Very slow animation (600ms)
  static const Duration animVerySlow = Duration(milliseconds: 600);

  // ============================================
  // BORDER WIDTHS
  // ============================================

  /// Thin border (1px)
  static const double borderThin = 1.0;

  /// Regular border (2px)
  static const double border = 2.0;

  /// Thick border (3px)
  static const double borderThick = 3.0;

  // ============================================
  // BLUR
  // ============================================

  /// Light blur
  static const double blurLight = 10.0;

  /// Medium blur
  static const double blurMedium = 20.0;

  /// Heavy blur
  static const double blurHeavy = 25.0;

  /// Very heavy blur
  static const double blurVeryHeavy = 30.0;

  // ============================================
  // HELPERS
  // ============================================

  /// Get horizontal padding based on screen size
  static double getScreenPaddingH(BuildContext context) {
    final width = MediaQuery.of(context).size.shortestSide;
    return width >= 600 ? screenPaddingHTablet : screenPaddingH;
  }

  /// Check if device is tablet (shortestSide >= 600)
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 600;
  }

  /// Check if device is a small phone (height < 700, e.g. iPhone SE, 8)
  static bool isSmallDevice(BuildContext context) {
    return MediaQuery.of(context).size.height < 700;
  }

  /// Check if device is a large phone (height >= 900, e.g. iPhone Pro Max)
  static bool isLargePhone(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.height >= 900 && size.shortestSide < 600;
  }

  /// Returns a continuous scale factor based on screen height.
  /// Baseline is 844px (iPhone 14/15 logical height).
  /// Returns ~0.82 for SE (667px), ~1.0 for 14 (844px),
  /// ~1.06 for Pro Max (932px), ~1.2+ for tablets.
  static double responsiveScale(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return (height / 844).clamp(0.75, 1.4);
  }

  /// Scale a value proportionally to screen height.
  /// Useful for icon sizes, spacing, and font sizes that should
  /// shrink on small phones and grow on tablets.
  static double scaled(BuildContext context, double value) {
    return value * responsiveScale(context);
  }

  /// Get bottom safe area padding
  static double getBottomPadding(BuildContext context) {
    final padding = MediaQuery.of(context).padding.bottom;
    return padding > 0 ? padding : spaceM;
  }

  /// Standard card decoration box shadow
  static List<BoxShadow> cardShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: shadowOpacityLight),
          blurRadius: shadowBlurM,
          offset: const Offset(0, shadowOffsetS),
        ),
      ];

  /// Elevated shadow for buttons/FABs
  static List<BoxShadow> elevatedShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: shadowOpacityGlow),
          blurRadius: shadowBlurL,
          offset: const Offset(0, shadowOffsetL),
        ),
      ];

  /// Bottom bar shadow
  static List<BoxShadow> bottomBarShadow() => [
        BoxShadow(
          color: Colors.black.withValues(alpha: shadowOpacityMedium),
          blurRadius: shadowBlurM,
          offset: const Offset(0, -shadowOffsetM),
        ),
      ];
}
