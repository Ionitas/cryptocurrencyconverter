import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'core/services/onboarding_service.dart';
import 'core/services/currency_sync_service.dart';
import 'core/services/subscription/subscription_service.dart';
import 'core/services/subscription/subscription_manager.dart';
import 'core/services/analytics/firebase_analytics_service.dart';
import 'core/services/analytics/analytics_manager.dart';
import 'core/services/startup/startup_manager.dart';
import 'core/services/startup/app_lifecycle_manager.dart';
import 'firebase_options.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/no_internet_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/onboarding/onboarding_screen.dart';

void main() async {
  final startupTimer = Stopwatch()..start();

  WidgetsFlutterBinding.ensureInitialized();

  final isMobile = !kIsWeb && (Platform.isIOS || Platform.isAndroid);
  final isDesktop =
      !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

  // PHASE 1: Critical platform setup (must be sequential)
  await _setupPlatform(isMobile, isDesktop);

  // PHASE 2: Parallel initialization of core services
  await _initializeCoreServices(isMobile);

  // PHASE 3: Setup dependency injection
  await setupDependencies();

  startupTimer.stop();
  debugPrint('🚀 Startup completed in ${startupTimer.elapsedMilliseconds}ms');

  // Log startup performance
  FirebaseAnalyticsService.instance.logStartupPerformance(
    totalDurationMs: startupTimer.elapsedMilliseconds,
    taskDurations: StartupManager.instance.taskTimes.map(
      (key, value) => MapEntry(key, value.inMilliseconds),
    ),
  );

  runApp(const MyApp());

  // PHASE 4: Deferred initialization (after app starts)
  _runDeferredTasks(isMobile);
}

/// Setup platform-specific configuration
Future<void> _setupPlatform(bool isMobile, bool isDesktop) async {
  if (isMobile) {
    // Lock orientation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  if (isDesktop) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(400, 800),
      minimumSize: Size(360, 720),
      maximumSize: Size(480, 900),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setPreventClose(true);
    });
  }
}

/// Initialize core services in parallel for faster startup
Future<void> _initializeCoreServices(bool isMobile) async {
  final futures = <Future<void>>[];

  // Firebase (mobile only)
  if (isMobile) {
    futures.add(_initFirebase());
  }

  // Wait for all parallel initializations
  await Future.wait(futures);
}

Future<void> _initFirebase() async {
  try {
    final timer = Stopwatch()..start();
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseAnalyticsService.instance.init();
    timer.stop();
    debugPrint('✓ Firebase initialized in ${timer.elapsedMilliseconds}ms');
  } catch (e) {
    debugPrint('✗ Firebase initialization failed: $e');
  }
}

/// Run deferred tasks after app has started
void _runDeferredTasks(bool isMobile) {
  // Delay to ensure app is fully rendered
  Future.delayed(const Duration(milliseconds: 500), () async {
    // Initialize RevenueCat (can be deferred on mobile)
    if (isMobile) {
      try {
        await SubscriptionService.instance.init();
        debugPrint('✓ RevenueCat initialized (deferred)');
      } catch (e) {
        debugPrint('✗ RevenueCat initialization failed: $e');
      }
    }

    // Start analytics session
    getIt<AnalyticsManager>().startSession();
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final AppTheme _appTheme;
  bool _showSplash = true;
  bool _showOnboarding = true;
  bool _checkingOnboarding = true;
  bool _noInternet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appTheme = getIt<AppTheme>();
    _appTheme.addListener(_onThemeChanged);

    // Initialize lifecycle manager
    AppLifecycleManager.instance.init();

    _checkInitialState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        AppLifecycleManager.instance.onForeground();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        AppLifecycleManager.instance.onBackground();
        // End analytics session when backgrounded
        getIt<AnalyticsManager>().endSession();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _checkInitialState() async {
    // Run checks in parallel for speed
    final futures = await Future.wait([
      _checkOnboardingStatus(),
      _preloadData(),
    ]);

    final completed = futures[0] as bool;

    // If first time user (onboarding not completed), check internet
    if (!completed) {
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet && mounted) {
        setState(() {
          _noInternet = true;
          _checkingOnboarding = false;
        });
        return;
      }
    }

    if (mounted) {
      setState(() {
        _showOnboarding = !completed;
        _checkingOnboarding = false;
        _noInternet = false;
      });
    }
  }

  Future<bool> _checkOnboardingStatus() async {
    final onboardingService = OnboardingService();
    return await onboardingService.isOnboardingCompleted();
  }

  Future<void> _preloadData() async {
    // Pre-initialize sync service for returning users
    // This runs during splash, so data is ready when dashboard loads
    try {
      final onboardingService = OnboardingService();
      final completed = await onboardingService.isOnboardingCompleted();

      if (completed) {
        // For returning users, start loading data immediately
        final syncService = getIt<CurrencySyncService>();
        await syncService.initialize(isFirstTime: false);
      }
    } catch (e) {
      debugPrint('Preload data failed: $e');
    }
  }

  /// Called when splash screen animation completes
  void _onSplashComplete() {
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void _onRetryInternet() {
    setState(() {
      _checkingOnboarding = true;
      _noInternet = false;
    });
    _checkInitialState();
  }

  void _onOnboardingComplete() {
    setState(() {
      _showOnboarding = false;
    });
    // Mark that paywall was shown during onboarding so we don't show again immediately
    SubscriptionManager.instance.markPaywallShownThisSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appTheme.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Update system UI overlay style based on theme
    final isLightTheme = _appTheme.currentTheme == ThemeOption.light;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          isLightTheme ? Brightness.dark : Brightness.light,
      statusBarBrightness: isLightTheme ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: _appTheme.background,
      systemNavigationBarIconBrightness:
          isLightTheme ? Brightness.dark : Brightness.light,
    ));

    final analyticsObserver = FirebaseAnalyticsService.instance.observer;
    return MaterialApp(
      title: 'Currency Ex',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        if (analyticsObserver != null) analyticsObserver,
      ],
      theme: ThemeData(
        useMaterial3: true,
        brightness: isLightTheme ? Brightness.light : Brightness.dark,
        scaffoldBackgroundColor: _appTheme.background,
        primaryColor: _appTheme.primary,
        colorScheme: ColorScheme(
          brightness: isLightTheme ? Brightness.light : Brightness.dark,
          primary: _appTheme.primary,
          onPrimary: Colors.white,
          secondary: _appTheme.accent,
          onSecondary: Colors.white,
          error: _appTheme.error,
          onError: Colors.white,
          surface: _appTheme.surface,
          onSurface: _appTheme.textPrimary,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: _appTheme.background,
          foregroundColor: _appTheme.textPrimary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: _appTheme.surface,
          elevation: 0,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: _appTheme.surface,
          titleTextStyle: TextStyle(
            color: _appTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: _appTheme.surface,
          contentTextStyle: TextStyle(color: _appTheme.textPrimary),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _appTheme.primary;
            }
            return _appTheme.surfaceLight;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _appTheme.primary.withValues(alpha: 0.5);
            }
            return _appTheme.surfaceLight.withValues(alpha: 0.5);
          }),
        ),
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    // Show splash screen first
    if (_showSplash) {
      // Shorter splash for returning users (data preloaded)
      final duration = _showOnboarding
          ? const Duration(milliseconds: 2000)
          : const Duration(milliseconds: 1200);

      return SplashScreen(
        onAnimationComplete: _onSplashComplete,
        minimumDisplayDuration: duration,
      );
    }

    // Still checking onboarding status
    if (_checkingOnboarding) {
      return _buildLoadingScreen();
    }

    // No internet for first-time users
    if (_noInternet) {
      return NoInternetScreen(
        appTheme: _appTheme,
        onRetry: _onRetryInternet,
      );
    }

    // Show onboarding or main app with fade transition
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _showOnboarding
          ? OnboardingScreen(
              key: const ValueKey('onboarding'),
              onComplete: _onOnboardingComplete,
            )
          : const DashboardScreen(key: ValueKey('dashboard')),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: _appTheme.background,
      body: Center(
        child: CircularProgressIndicator(
          color: _appTheme.primary,
        ),
      ),
    );
  }
}
