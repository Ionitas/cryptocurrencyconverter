import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Splash screen shown during app startup
/// Displays app branding while services initialize
class SplashScreen extends StatefulWidget {
  final VoidCallback? onAnimationComplete;
  final Duration minimumDisplayDuration;

  const SplashScreen({
    super.key,
    this.onAnimationComplete,
    this.minimumDisplayDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _pulseAnimation;

  // Brand colors (matching app theme)
  static const Color _backgroundColor = Color(0xFF0A0E21);
  static const Color _primaryColor = Color(0xFF6C5CE7);
  static const Color _accentColor = Color(0xFF00D9FF);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();

    // Set status bar style for splash
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: _backgroundColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  void _setupAnimations() {
    // Logo entrance animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Text fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );

    // Pulse animation for loading indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startAnimations() async {
    // Start logo animation
    _logoController.forward();

    // Start text animation after logo
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) _fadeController.forward();

    // Start pulsing animation
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) _pulseController.repeat(reverse: true);

    // Minimum display time
    await Future.delayed(widget.minimumDisplayDuration);
    widget.onAnimationComplete?.call();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E21),
              Color(0xFF1A1F3C),
              Color(0xFF0A0E21),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Animated logo
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScale.value,
                      child: Opacity(
                        opacity: _logoOpacity.value,
                        child: _buildLogo(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // App name with animation
                AnimatedBuilder(
                  animation: _fadeController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - _textOpacity.value)),
                        child: _buildAppName(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Tagline
                AnimatedBuilder(
                  animation: _fadeController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textOpacity.value * 0.7,
                      child: const Text(
                        'Real-time Currency Converter',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(flex: 2),

                // Loading indicator
                AnimatedBuilder(
                  animation:
                      Listenable.merge([_fadeController, _pulseController]),
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textOpacity.value,
                      child: Transform.scale(
                        scale: _pulseAnimation.value,
                        child: _buildLoadingIndicator(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Loading text
                AnimatedBuilder(
                  animation: _fadeController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textOpacity.value * 0.5,
                      child: const Text(
                        'Loading...',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.4),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.2),
            blurRadius: 60,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Image.asset(
          'assets/images/icon.png',
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildAppName() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.white, Color(0xFFE0E0E0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bounds),
      child: const Text(
        'Currency Ex',
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        // Animated loading bar
        SizedBox(
          width: 180,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                _accentColor.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Animated dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.3, end: 1.0),
              duration: Duration(milliseconds: 600 + (index * 200)),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accentColor.withValues(alpha: value * 0.8),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
