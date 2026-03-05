import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// Welcome screen - first onboarding page
class WelcomePage extends StatefulWidget {
  final AppTheme appTheme;
  final VoidCallback onContinue;
  final bool isDataLoading;
  final String loadingStatus;
  final int currencyCount;

  const WelcomePage({
    super.key,
    required this.appTheme,
    required this.onContinue,
    this.isDataLoading = false,
    this.loadingStatus = '',
    this.currencyCount = 0,
  });

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = widget.appTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmall = DesignTokens.isSmallDevice(context);
    final scale = DesignTokens.responsiveScale(context);

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return SingleChildScrollView(
          primary: false,
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight,
            ),
            child: Column(
              children: [
                SizedBox(
                    height: DesignTokens.scaled(context, isSmall ? 40 : 60)),

                // App icon with enhanced animation and glow effect
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: _buildAppIcon(appTheme, scale),
                  ),
                ),

                SizedBox(
                    height: DesignTokens.scaled(context, isSmall ? 32 : 48)),

                // Welcome text with improved typography
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildWelcomeText(appTheme, isSmall, scale),
                  ),
                ),

                SizedBox(
                    height: DesignTokens.scaled(context, isSmall ? 40 : 60)),

                // Feature highlights with staggered entrance
                _buildFeatureHighlights(appTheme, scale),

                SizedBox(
                    height: DesignTokens.scaled(context, isSmall ? 24 : 32)),

                // Loading status indicator
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildLoadingStatus(appTheme),
                ),

                SizedBox(
                    height: DesignTokens.scaled(context, isSmall ? 16 : 24)),

                // Get Started button
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildGetStartedButton(appTheme),
                ),

                SizedBox(height: DesignTokens.getBottomPadding(context) + 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppIcon(AppTheme appTheme, double scale) {
    final glowSize = (140 * scale).roundToDouble();
    final iconSize = (120 * scale).roundToDouble();
    final borderRadius = (32 * scale).roundToDouble();

    return Stack(
      alignment: Alignment.center,
      children: [
        // Animated glow ring
        AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return Container(
              width: glowSize,
              height: glowSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    appTheme.primary.withValues(alpha: 0.0),
                    appTheme.primary.withValues(alpha: 0.3),
                    appTheme.accent.withValues(alpha: 0.3),
                    appTheme.primary.withValues(alpha: 0.0),
                  ],
                  transform: GradientRotation(_shimmerController.value * 6.28),
                ),
              ),
            );
          },
        ),
        // Icon container
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: appTheme.primary.withValues(alpha: 0.5),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: appTheme.accent.withValues(alpha: 0.2),
                blurRadius: 60,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.asset(
              'assets/images/icon.png',
              width: iconSize,
              height: iconSize,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeText(
      AppTheme appTheme, bool isSmallScreen, double scale) {
    final titleSize = (isSmallScreen ? 28.0 : 34.0) * scale;
    final subtitleSize = (isSmallScreen ? 15.0 : 16.0) * scale;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: appTheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: appTheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            '✨ Welcome',
            style: TextStyle(
              color: appTheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [appTheme.textPrimary, appTheme.textPrimary],
            ).createShader(bounds),
            child: Text(
              'Currency Ex',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: appTheme.textPrimary,
                fontSize: titleSize.clamp(24, 42),
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Convert currencies instantly with real-time exchange rates',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: appTheme.textSecondary,
              fontSize: subtitleSize.clamp(13, 18),
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureHighlights(AppTheme appTheme, double scale) {
    final features = [
      ('🌍', '225+ Currencies'),
      ('⚡', 'Real-time Rates'),
      ('📊', 'Smart Calculator'),
    ];

    final itemHeight = (90 * scale).clamp(76, 110).toDouble();
    final emojiSize = (26 * scale).clamp(20, 32).toDouble();

    return SizedBox(
      height: itemHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: features.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final feature = features[index];
          // Staggered entrance: each card fades/slides in with a delay
          final staggerInterval = Interval(
            (0.3 + index * 0.12).clamp(0.0, 1.0),
            (0.7 + index * 0.12).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          );
          final itemFade = CurvedAnimation(
            parent: _animController,
            curve: staggerInterval,
          );
          return FadeTransition(
            opacity: itemFade,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(itemFade),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: appTheme.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: appTheme.surfaceLight.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      feature.$1,
                      style: TextStyle(fontSize: emojiSize),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature.$2,
                      style: TextStyle(
                        color: appTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingStatus(AppTheme appTheme) {
    if (widget.loadingStatus.isEmpty) {
      return const SizedBox(height: 24);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(widget.loadingStatus),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: appTheme.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.currencyCount > 0 && !widget.isDataLoading
                ? appTheme.success.withValues(alpha: 0.3)
                : appTheme.surfaceLight.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isDataLoading) ...[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: appTheme.accent,
                ),
              ),
              const SizedBox(width: 12),
            ] else if (widget.currencyCount > 0) ...[
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: appTheme.success.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 12,
                  color: appTheme.success,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              widget.loadingStatus,
              style: TextStyle(
                color: appTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGetStartedButton(AppTheme appTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onContinue();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                appTheme.primary,
                appTheme.primary.withValues(alpha: 0.9),
                appTheme.accent.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: appTheme.primary.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: appTheme.accent.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Get Started',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
