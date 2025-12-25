import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/di/injection.dart';
import '../../core/theme/app_theme.dart';
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
  late PageController _pageController;
  int _currentIndex = 0;

  // Global keys to access child screen methods
  final GlobalKey<ConverterScreenState> _converterKey =
      GlobalKey<ConverterScreenState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _appTheme.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _appTheme.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  void _switchTab(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appTheme.background,
      appBar: _buildAppBar(),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: [
          ConverterScreen(key: _converterKey),
          const PortfolioScreen(key: ValueKey('portfolio')),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _appTheme.background,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: false,
      title: Row(
        children: [
          _buildTabButton(
            index: 0,
            label: 'Converter',
          ),
          const SizedBox(width: 24),
          _buildTabButton(
            index: 1,
            label: 'Portfolio',
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: _appTheme.textPrimary),
          onPressed: () {
            HapticFeedback.lightImpact();
            _converterKey.currentState?.refreshData();
          },
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: Icon(Icons.settings, color: _appTheme.textPrimary),
          onPressed: () {
            HapticFeedback.lightImpact();
            _converterKey.currentState?.showSettings();
          },
          tooltip: 'Settings',
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _switchTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        style: TextStyle(
          color: isSelected ? _appTheme.accent : _appTheme.textTertiary,
          fontSize: isSelected ? 20 : 18,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
        child: Text(label),
      ),
    );
  }
}
