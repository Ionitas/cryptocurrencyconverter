import 'package:flutter/material.dart';
import '../../core/di/injection.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/analytics/logging_system.dart';
import '../../core/services/analytics/analytics_manager.dart';
import '../../core/services/subscription/subscription_manager.dart';
import '../../core/services/startup/app_lifecycle_manager.dart';
import '../../core/services/currency_sync_service.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/subscription_paywall.dart';
import '../controllers/dashboard_controller.dart';
import 'converter_screen.dart';
import 'portfolio/portfolio_screen.dart';

/// Dashboard screen with swipeable navigation between Converter and Portfolio
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AppTheme _appTheme = getIt<AppTheme>();
  final CurrencySyncService _syncService = getIt<CurrencySyncService>();
  late DashboardController _controller;

  // Global keys to access child screen methods
  final GlobalKey<ConverterScreenState> _converterKey =
      GlobalKey<ConverterScreenState>();
  final GlobalKey<PortfolioScreenState> _portfolioKey =
      GlobalKey<PortfolioScreenState>();

  @override
  void initState() {
    super.initState();
    _controller = DashboardController();
    _controller.addListener(_onControllerChanged);
    _appTheme.addListener(_onThemeChanged);

    // Register for lifecycle events
    AppLifecycleManager.instance.addForegroundListener(_onAppForeground);

    // Log screen view
    getIt<AnalyticsManager>().logScreenView('dashboard');

    // Check if we should show paywall on this app open
    _checkAndShowPaywall();
  }

  /// Called when app returns to foreground
  void _onAppForeground() {
    getIt<AnalyticsManager>().logUserEngagement(action: 'app_foreground');
    // Refresh data if it might be stale
    if (AppLifecycleManager.instance.shouldRefreshData) {
      AppLogger.i('Dashboard', 'App returned from background, refreshing data');
      _syncService.syncNow(forceRefresh: false);
    }
  }

  /// Check if paywall should be shown (every 3rd app open)
  Future<void> _checkAndShowPaywall() async {
    // Wait for the screen to be built first
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final shouldShow =
        await SubscriptionManager.instance.incrementAppOpenAndCheckPaywall();

    if (shouldShow && mounted) {
      // Log paywall view
      getIt<AnalyticsManager>().logPaywallView(
        source: 'periodic',
        currencyCount: _syncService.currencies.length,
      );
      await SubscriptionPaywall.show(context);
    }
  }

  @override
  void dispose() {
    AppLifecycleManager.instance.removeForegroundListener(_onAppForeground);
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _appTheme.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  void _onThemeChanged() {
    setState(() {});
  }

  void _handleRefresh() {
    final screen = _controller.currentIndex == 0 ? 'Converter' : 'Portfolio';
    AppLogger.i('Dashboard', 'Refresh requested for $screen');

    if (_controller.currentIndex == 0) {
      _converterKey.currentState?.refreshData();
    } else {
      _portfolioKey.currentState?.refreshData();
    }
  }

  void _handleSettings() {
    final screen = _controller.currentIndex == 0 ? 'Converter' : 'Portfolio';
    AppLogger.i('Dashboard', 'Settings requested for $screen');

    if (_controller.currentIndex == 0) {
      _converterKey.currentState?.showSettings();
    } else {
      _portfolioKey.currentState?.showSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appTheme.background,
      appBar: DashboardAppBar(
        appTheme: _appTheme,
        currentIndex: _controller.currentIndex,
        tabs: const ['Converter', 'Portfolio'],
        onTabChanged: _controller.switchTab,
        onRefresh: _handleRefresh,
        onSettings: _handleSettings,
      ),
      body: PageView(
        controller: _controller.pageController,
        onPageChanged: _controller.onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: [
          ConverterScreen(key: _converterKey),
          PortfolioScreen(key: _portfolioKey),
        ],
      ),
    );
  }
}
