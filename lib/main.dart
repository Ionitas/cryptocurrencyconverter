import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'core/services/onboarding_service.dart';
import 'presentation/screens/converter_screen.dart';
import 'presentation/screens/no_internet_screen.dart';
import 'presentation/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait only on mobile devices
  final isMobile = Platform.isIOS || Platform.isAndroid;
  if (isMobile) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Setup window for desktop platforms
  final isDesktop = Platform.isLinux || Platform.isWindows || Platform.isMacOS;
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

  // Setup dependency injection
  await setupDependencies();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppTheme _appTheme;
  bool _showOnboarding = true;
  bool _checkingOnboarding = true;
  bool _noInternet = false;

  @override
  void initState() {
    super.initState();
    _appTheme = getIt<AppTheme>();
    _appTheme.addListener(_onThemeChanged);
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    final onboardingService = OnboardingService();
    final completed = await onboardingService.isOnboardingCompleted();

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
  }

  @override
  void dispose() {
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

    return MaterialApp(
      title: 'Currency Converter',
      debugShowCheckedModeBanner: false,
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
              return _appTheme.primary.withOpacity(0.5);
            }
            return _appTheme.surfaceLight.withOpacity(0.5);
          }),
        ),
      ),
      home: _checkingOnboarding
          ? _buildLoadingScreen()
          : _noInternet
              ? NoInternetScreen(
                  appTheme: _appTheme,
                  onRetry: _onRetryInternet,
                )
              : _showOnboarding
                  ? OnboardingScreen(onComplete: _onOnboardingComplete)
                  : const ConverterScreen(),
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
