import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/repositories/currency_repository.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/currency_sync_service.dart';
import '../../../core/services/onboarding_service.dart';
import '../../../core/services/analytics/logging_system.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/settings_dialog.dart';
import 'portfolio_controller.dart';
import 'widgets/widgets.dart';
import 'widgets/add_portfolio_entry_modal.dart';

/// Portfolio screen for aggregating multiple currency amounts
class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => PortfolioScreenState();
}

class PortfolioScreenState extends State<PortfolioScreen> with SingleTickerProviderStateMixin {
  late final PortfolioController _controller;
  final AppTheme _appTheme = getIt<AppTheme>();
  final CurrencySyncService _syncService = getIt<CurrencySyncService>();
  final OnboardingService _onboardingService = OnboardingService();

  StreamSubscription<List<dynamic>>? _currencySubscription;
  late AnimationController _fadeController;

  // User country info
  String? _userCountry;
  String? _userCountryFlag;
  String? _userCurrencyCode;

  // Track keyboard visibility
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = PortfolioController(repository: getIt<CurrencyRepository>());
    _controller.addListener(_onControllerChanged);
    _appTheme.addListener(_onThemeChanged);

    // Smooth fade-in animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Listen to currency updates from sync service
    _currencySubscription = _syncService.currencyStream.listen((_) {
      // Reload currencies when sync service updates
      _controller.loadCurrencies();
    });

    _controller.loadCurrencies().then((_) {
      _fadeController.forward();
    });

    // Load user country info
    _loadUserCountryInfo();
  }

  /// Load user country information from onboarding
  Future<void> _loadUserCountryInfo() async {
    final onboardingData = await _onboardingService.loadOnboardingData();
    if (mounted) {
      setState(() {
        _userCountry = onboardingData.country;
        _userCurrencyCode = onboardingData.currencyCode;
        if (onboardingData.countryCode != null) {
          _userCountryFlag = _getFlagEmoji(onboardingData.countryCode!);
        }
      });
    }
  }

  /// Convert country code to flag emoji
  String _getFlagEmoji(String countryCode) {
    final code = countryCode.toUpperCase();
    if (code.length != 2) return '🌍';
    final firstLetter = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final secondLetter = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }

  @override
  void dispose() {
    _currencySubscription?.cancel();
    _controller.removeListener(_onControllerChanged);
    _appTheme.removeListener(_onThemeChanged);
    _fadeController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  void _onThemeChanged() {
    setState(() {});
  }

  // Public methods accessible via GlobalKey
  void refreshData() {
    AppLogger.buttonTap('refreshData (Portfolio)');
    AppLogger.i('Portfolio', 'Starting force refresh...');
    final startTime = DateTime.now();

    _syncService.syncNow(forceRefresh: true).then((result) {
      final duration = DateTime.now().difference(startTime);
      AppLogger.s('Portfolio',
          'Refresh complete in ${duration.inMilliseconds}ms - ${result.currencies.length} currencies, fromCache: ${result.fromCache}');

      _controller.loadCurrencies();
      if (mounted) {
        SnackBarHelper.show(
          context: context,
          message: 'Data refreshed',
          appTheme: _appTheme,
          type: SnackBarType.success,
          duration: const Duration(seconds: 1),
        );
      }
    }).catchError((error) {
      AppLogger.e('Portfolio', 'Refresh failed', error: error);
    });
  }

  void showSettings() async {
    AppLogger.buttonTap('showSettings (Portfolio)');
    final lastUpdate = await _controller.repository.getLastUpdateTime();
    final nextUpdate = _controller.repository.getNextUpdateTime();

    if (!mounted) return;

    SettingsDialog.show(
      context: context,
      fromCache: _syncService.lastSyncFromCache,
      nextUpdate: nextUpdate,
      lastUpdate: lastUpdate,
      currencyCount: _controller.allCurrencies.length,
      onForceRefresh: () async {
        await _syncService.syncNow(forceRefresh: true);
        _controller.loadCurrencies();
      },
      appTheme: _appTheme,
      userCountry: _userCountry,
      userCountryFlag: _userCountryFlag,
      userCurrencyCode: _userCurrencyCode,
    );
  }

  void _showChangeCurrencyPicker() {
    CurrencyPickerModal.show(
      context: context,
      currencies: _controller.allCurrencies,
      onSelect: (currency) {
        _controller.setBaseCurrency(currency);
        Navigator.pop(context);
        SnackBarHelper.show(
          context: context,
          message: 'Base currency changed to ${currency.symbol}',
          appTheme: _appTheme,
          type: SnackBarType.info,
          duration: const Duration(seconds: 1),
        );
      },
      appTheme: _appTheme,
      mode: CurrencyPickerMode.change,
      customTitle: 'Select Base Currency',
    );
  }

  void _showAddEntryModal() {
    AddPortfolioEntryModal.show(
      context: context,
      allCurrencies: _controller.allCurrencies,
      onAdd: (currency, amount) {
        _controller.addEntry(currency, amount);
        SnackBarHelper.show(
          context: context,
          message: '${currency.symbol} added to portfolio',
          appTheme: _appTheme,
          type: SnackBarType.success,
          duration: const Duration(seconds: 1),
        );
      },
      appTheme: _appTheme,
    );
  }

  void _removeEntry(String id) {
    final removed = _controller.removeEntry(id);
    if (removed != null) {
      SnackBarHelper.show(
        context: context,
        message: '${removed.currency.symbol} removed',
        appTheme: _appTheme,
        type: SnackBarType.info,
        duration: const Duration(seconds: 1),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final hasKeyboard = keyboardHeight > 0;

    // Update keyboard visibility state
    if (hasKeyboard != _isKeyboardVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isKeyboardVisible = hasKeyboard;
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: _appTheme.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _controller.isLoading
                  ? _buildLoadingState()
                  : FadeTransition(
                      opacity: _fadeController,
                      child: _buildContent(),
                    ),
            ),
            // Keyboard Done button overlay
            if (hasKeyboard)
              Positioned(
                left: 0,
                right: 0,
                bottom: keyboardHeight,
                child: _buildKeyboardDoneBar(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardDoneBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _appTheme.surface,
        border: Border(
          top: BorderSide(
            color: _appTheme.surfaceLight.withOpacity(0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              FocusScope.of(context).unfocus();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _appTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Done',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      key: const ValueKey('loading'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: CircularProgressIndicator(color: _appTheme.primary),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Text(
                  'Loading currencies...',
                  style: TextStyle(
                    color: _appTheme.textTertiary,
                    fontSize: 14,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.shortestSide >= 600;
    final horizontalPadding = isTablet ? 24.0 : 16.0;

    return Column(
      children: [
        // Total section with base currency
        PortfolioTotalSection(
          total: _controller.total,
          baseCurrency: _controller.baseCurrency,
          entryCount: _controller.entryCount,
          formatAmount: _controller.formatAmount,
          appTheme: _appTheme,
          onChangeCurrency: _showChangeCurrencyPicker,
        ),
        // Entries list or empty state
        Expanded(
          child: _controller.entries.isEmpty
              ? PortfolioEmptyState(
                  appTheme: _appTheme,
                  onAddCurrency: _showAddEntryModal,
                )
              : _buildEntriesList(horizontalPadding),
        ),
        // Add button (only show when there are entries)
        if (_controller.entries.isNotEmpty)
          PortfolioAddButton(
            appTheme: _appTheme,
            onTap: _showAddEntryModal,
          ),
      ],
    );
  }

  Widget _buildEntriesList(double padding) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12),
      itemCount: _controller.entries.length,
      itemBuilder: (context, index) {
        final entry = _controller.entries[index];
        final convertedAmount = _controller.getConvertedAmount(entry);

        return PortfolioEntryCard(
          entry: entry,
          baseCurrency: _controller.baseCurrency,
          convertedAmount: convertedAmount,
          appTheme: _appTheme,
          formatAmount: _controller.formatAmount,
          onAmountChanged: (newAmount) => _controller.updateEntryAmount(entry.id, newAmount),
          onRemove: () => _removeEntry(entry.id),
        );
      },
    );
  }
}
