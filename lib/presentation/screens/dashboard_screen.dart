import 'package:flutter/material.dart';
import '../../core/di/injection.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/analytics/logging_system.dart';
import '../widgets/dashboard_app_bar.dart';
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
  late DashboardController _controller;

  // Global keys to access child screen methods
  final GlobalKey<ConverterScreenState> _converterKey = GlobalKey<ConverterScreenState>();
  final GlobalKey<PortfolioScreenState> _portfolioKey = GlobalKey<PortfolioScreenState>();

  @override
  void initState() {
    super.initState();
    _controller = DashboardController();
    _controller.addListener(_onControllerChanged);
    _appTheme.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
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
