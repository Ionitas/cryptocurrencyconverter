import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/models/currency.dart';
import '../../domain/repositories/currency_repository.dart';
import '../../core/di/injection.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/services/onboarding_service.dart';
import '../../core/services/portfolio_storage_service.dart';
import '../../core/services/currency_sync_service.dart';
import '../../core/services/analytics/logging_system.dart';
import '../../core/services/subscription/subscription_manager.dart';
import '../widgets/widgets.dart';
import '../widgets/subscription_paywall.dart';
import '../widgets/upgrade_to_premium_widget.dart';
import '../utils/calculator_logic.dart';
import '../utils/snackbar_helper.dart';

/// Main converter screen for currency conversion
class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => ConverterScreenState();
}

class ConverterScreenState extends State<ConverterScreen>
    with TickerProviderStateMixin, CalculatorLogic {
  final CurrencyRepository _repository = getIt<CurrencyRepository>();
  final CurrencySyncService _syncService = getIt<CurrencySyncService>();
  final AppTheme _appTheme = getIt<AppTheme>();
  final OnboardingService _onboardingService = OnboardingService();
  final PortfolioStorageService _storageService = PortfolioStorageService();

  // Stream subscriptions
  StreamSubscription<List<Currency>>? _currencySubscription;
  StreamSubscription<SyncState>? _syncStateSubscription;

  // Currency data
  List<Currency> _allCurrencies = [];
  Currency? _selectedCurrency;
  List<Currency> _displayCurrencies = [];

  // Default currencies - BTC, USD and user's country currency
  List<String> _displayCurrencyOrder = ['BTC', 'USD', 'EUR', 'GBP'];
  Set<String> _displayCurrencySymbols = {'BTC', 'USD', 'EUR', 'GBP'};

  // User's country currency
  String? _userCurrencyCode;
  String? _userCountry;
  String? _userCountryFlag;

  // UI state
  bool _isLoading = true;
  String _statusMessage = '';
  bool _fromCache = false;

  // Calculator animation state
  late AnimationController _calculatorController;
  late Animation<double> _calculatorAnimation;
  double _dragOffset = 0;
  bool _isDragging = false;
  double _calculatorHeight = 0;

  @override
  void initState() {
    super.initState();
    currentAmount = 0.5;
    displayValue = '0.5';
    _appTheme.addListener(_onThemeChanged);

    // Initialize calculator animation with smoother curves
    _calculatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 320),
    );
    _calculatorAnimation = CurvedAnimation(
      parent: _calculatorController,
      curve: Curves.easeOutExpo,
      reverseCurve: Curves.easeInCubic,
    );
    _calculatorController.value = 1.0; // Start visible

    // Subscribe to currency updates stream
    _setupStreamSubscriptions();

    _initializeWithUserPreferences();
  }

  /// Setup stream subscriptions for live data updates
  void _setupStreamSubscriptions() {
    // Listen to currency updates
    _currencySubscription = _syncService.currencyStream.listen((currencies) {
      if (currencies.isNotEmpty && mounted) {
        _updateCurrenciesFromStream(currencies);
      }
    });

    // Listen to sync state changes
    _syncStateSubscription = _syncService.syncStateStream.listen((state) {
      if (mounted) {
        // Show subtle indicator when background sync completes
        if (state == SyncState.synced && !_syncService.lastSyncFromCache) {
          _showBackgroundSyncComplete();
        }
      }
    });
  }

  /// Update currencies when stream emits new data
  void _updateCurrenciesFromStream(List<Currency> currencies) {
    final oldSelected = _selectedCurrency;
    _allCurrencies = currencies;

    // Preserve selected currency if still available
    if (oldSelected != null) {
      _selectedCurrency = _allCurrencies.firstWhere(
        (c) => c.symbol == oldSelected.symbol,
        orElse: () => _allCurrencies.first,
      );
    }

    _updateDisplayCurrencies();

    if (mounted) {
      setState(() {
        _fromCache = _syncService.lastSyncFromCache;
        _statusMessage = _syncService.lastSyncMessage;
      });
    }
  }

  void _showBackgroundSyncComplete() {
    if (!mounted) return;
    SnackBarHelper.show(
      context: context,
      message: '✓ Rates updated',
      appTheme: _appTheme,
      type: SnackBarType.success,
      duration: const Duration(seconds: 1),
    );
  }

  /// Load user preferences and then load currency data
  Future<void> _initializeWithUserPreferences() async {
    AppLogger.i('Converter', 'Initializing with user preferences...');

    // Load user's country from onboarding
    final onboardingData = await _onboardingService.loadOnboardingData();
    _userCurrencyCode = onboardingData.currencyCode;
    _userCountry = onboardingData.country;
    // Get flag from country code
    if (onboardingData.countryCode != null) {
      _userCountryFlag = _getFlagEmoji(onboardingData.countryCode!);
    }

    AppLogger.d('Converter',
        'User country: $_userCountry, currency: $_userCurrencyCode');

    // Load saved display currencies FIRST - this is the user's actual state
    final savedSymbols = await _storageService.loadConverterDisplaySymbols();
    final savedOrder = await _storageService.loadConverterDisplayOrder();

    AppLogger.d('Converter',
        'Loaded saved: symbols=${savedSymbols?.length}, order=${savedOrder?.length}');

    if (savedSymbols != null &&
        savedSymbols.isNotEmpty &&
        savedOrder != null &&
        savedOrder.isNotEmpty) {
      // User has saved state - use it exactly as saved
      _displayCurrencySymbols = savedSymbols;
      _displayCurrencyOrder = savedOrder;
      AppLogger.s(
          'Converter', 'Restored saved currencies: $_displayCurrencyOrder');
    } else {
      // First time - create defaults with user's country currency
      AppLogger.i('Converter', 'No saved state, creating defaults...');
      _displayCurrencyOrder = ['BTC', 'USD'];
      _displayCurrencySymbols = {'BTC', 'USD'};

      // Add user's country currency if different from USD
      if (_userCurrencyCode != null &&
          _userCurrencyCode != 'USD' &&
          !_displayCurrencySymbols.contains(_userCurrencyCode)) {
        _displayCurrencySymbols.add(_userCurrencyCode!);
        // Add after USD for prominence
        _displayCurrencyOrder.insert(2, _userCurrencyCode!);
        AppLogger.i('Converter', 'Added user currency: $_userCurrencyCode');
      }

      // Save these initial defaults
      await _storageService.saveConverterDisplayCurrencies(
        symbols: _displayCurrencySymbols,
        order: _displayCurrencyOrder,
      );
    }

    // Check if sync service already has data (from onboarding)
    if (_syncService.hasCachedData) {
      _allCurrencies = _syncService.currencies;
      await _restoreUserSelections();
      _updateDisplayCurrencies();
      setState(() {
        _isLoading = false;
        _fromCache = _syncService.lastSyncFromCache;
        _statusMessage = 'Loaded from cache';
      });

      // Initialize for background updates (not first time)
      _syncService.initialize(isFirstTime: false);
    } else {
      // No cached data, load fresh
      _loadData();
    }
  }

  Future<void> _restoreUserSelections() async {
    // Try to load saved currency, otherwise default to BTC
    final savedCurrencySymbol = await _storageService.loadConverterCurrency();
    if (savedCurrencySymbol != null) {
      _selectedCurrency = _allCurrencies.firstWhere(
        (c) => c.symbol == savedCurrencySymbol,
        orElse: () => _allCurrencies.firstWhere(
          (c) => c.symbol == 'BTC',
          orElse: () => _allCurrencies.first,
        ),
      );
    } else {
      _selectedCurrency = _allCurrencies.firstWhere(
        (c) => c.symbol == 'BTC',
        orElse: () => _allCurrencies.first,
      );
    }

    // Load saved amount
    final savedAmount = await _storageService.loadConverterAmount();
    if (savedAmount != null) {
      currentAmount = savedAmount;
      displayValue = formatCalculatorResult(savedAmount);
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
    _syncStateSubscription?.cancel();
    _appTheme.removeListener(_onThemeChanged);
    _calculatorController.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    AppLogger.i(
        'Converter', '_loadData() called - forceRefresh: $forceRefresh');

    setState(() {
      _isLoading = _allCurrencies.isEmpty;
      _statusMessage = forceRefresh ? 'Fetching fresh data...' : 'Loading...';
    });

    // Use sync service for data loading
    final startTime = DateTime.now();
    final result = forceRefresh
        ? await _syncService.syncNow(forceRefresh: true)
        : await _syncService.initialize(isFirstTime: false);

    final duration = DateTime.now().difference(startTime);

    if (result.currencies.isNotEmpty) {
      _allCurrencies = result.currencies;
      await _restoreUserSelections();
      _updateDisplayCurrencies();
      AppLogger.s('Converter',
          'Loaded ${_allCurrencies.length} currencies in ${duration.inMilliseconds}ms (fromCache: ${result.fromCache})');
    } else {
      AppLogger.w('Converter', 'No currencies returned from sync');
    }

    setState(() {
      _isLoading = false;
      _fromCache = result.fromCache;
      _statusMessage = result.message;
    });

    if (mounted && forceRefresh) {
      _showDataSnackBar(result.fromCache);
    }
  }

  void _showDataSnackBar(bool fromCache) {
    SnackBarHelper.show(
      context: context,
      message: fromCache
          ? '✓ Loaded from cache (${_allCurrencies.length} currencies)'
          : '✓ Fresh data (${_allCurrencies.length} currencies)',
      appTheme: _appTheme,
      type: fromCache ? SnackBarType.warning : SnackBarType.success,
    );
  }

  void _updateDisplayCurrencies() {
    final currencyMap = {for (var c in _allCurrencies) c.symbol: c};
    _displayCurrencies = _displayCurrencyOrder
        .where((symbol) =>
            _displayCurrencySymbols.contains(symbol) &&
            currencyMap.containsKey(symbol) &&
            currencyMap[symbol]!.id != _selectedCurrency?.id)
        .map((symbol) => currencyMap[symbol]!)
        .toList();
  }

  void _removeCurrency(Currency currency) {
    AppLogger.d('Converter', 'Removing currency: ${currency.symbol}');
    setState(() {
      _displayCurrencySymbols.remove(currency.symbol);
      _displayCurrencyOrder.remove(currency.symbol);
      _updateDisplayCurrencies();
    });
    // Fire and forget with error handling
    _saveConverterState().catchError((e) {
      AppLogger.e('Converter', 'Failed to save after remove', error: e);
    });
  }

  void _addCurrency(Currency currency) {
    AppLogger.d('Converter', 'Adding currency: ${currency.symbol}');
    AppLogger.d('Converter', 'Before add - symbols: $_displayCurrencySymbols');
    AppLogger.d('Converter', 'Before add - order: $_displayCurrencyOrder');

    setState(() {
      _displayCurrencySymbols.add(currency.symbol);
      if (!_displayCurrencyOrder.contains(currency.symbol)) {
        _displayCurrencyOrder.add(currency.symbol);
      }
      _updateDisplayCurrencies();
    });

    AppLogger.d('Converter', 'After add - symbols: $_displayCurrencySymbols');
    AppLogger.d('Converter', 'After add - order: $_displayCurrencyOrder');

    // Fire and forget with error handling
    _saveConverterState().catchError((e) {
      AppLogger.e('Converter', 'Failed to save after add', error: e);
    });

    SnackBarHelper.show(
      context: context,
      message: '${currency.symbol} added',
      appTheme: _appTheme,
      type: SnackBarType.success,
      duration: const Duration(seconds: 1),
    );
  }

  void _onReorderCurrencies(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final currency = _displayCurrencies.removeAt(oldIndex);
      _displayCurrencies.insert(newIndex, currency);
      _displayCurrencyOrder = _displayCurrencies.map((c) => c.symbol).toList();
      for (var symbol in _displayCurrencySymbols) {
        if (!_displayCurrencyOrder.contains(symbol)) {
          _displayCurrencyOrder.add(symbol);
        }
      }
    });
    _saveConverterState().catchError((e) {
      AppLogger.e('Converter', 'Failed to save after reorder', error: e);
    });
  }

  void _swapCurrency(Currency currency, int index) {
    setState(() {
      final convertedAmount = _repository.convert(
        currentAmount,
        _selectedCurrency!,
        currency,
      );

      _displayCurrencySymbols.add(_selectedCurrency!.symbol);
      if (!_displayCurrencyOrder.contains(_selectedCurrency!.symbol)) {
        _displayCurrencyOrder.insert(index, _selectedCurrency!.symbol);
      }
      _displayCurrencySymbols.remove(currency.symbol);
      _displayCurrencyOrder.remove(currency.symbol);
      _selectedCurrency = currency;
      currentAmount = convertedAmount;
      displayValue = formatCalculatorResult(convertedAmount);
      calculatorExpression = '';
      resetCalculatorState();
      _updateDisplayCurrencies();
    });

    // Save the new currency and amount
    _saveConverterState().catchError((e) {
      AppLogger.e('Converter', 'Failed to save after swap', error: e);
    });

    SnackBarHelper.show(
      context: context,
      message: '${currency.symbol} is now the main currency',
      appTheme: _appTheme,
      type: SnackBarType.info,
      duration: const Duration(seconds: 1),
    );
  }

  /// Save current converter state to storage
  Future<void> _saveConverterState() async {
    AppLogger.d('Converter',
        'Saving state: symbols=${_displayCurrencySymbols.length}, order=${_displayCurrencyOrder.length}');

    if (_selectedCurrency != null) {
      await _storageService.saveConverterState(
        amount: currentAmount,
        currencySymbol: _selectedCurrency!.symbol,
      );
    }
    // Save display currencies - await to ensure it completes
    await _storageService.saveConverterDisplayCurrencies(
      symbols: _displayCurrencySymbols,
      order: _displayCurrencyOrder,
    );

    AppLogger.s(
        'Converter', 'State saved: ${_displayCurrencyOrder.join(", ")}');
  }

  void _onCalculatorInput(String value) {
    setState(() {
      handleCalculatorInput(value);
    });
    // Save after calculator input - don't block, just fire and forget
    _saveConverterState().catchError((e) {
      AppLogger.e('Converter', 'Failed to save after calculator input',
          error: e);
    });
  }

  void _showCalculator() {
    _calculatorController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _hideCalculator() {
    _calculatorController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInQuad,
    );
  }

  void _onCalculatorDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) {
      setState(() => _isDragging = true);
    }
    final delta = details.delta.dy;
    if (delta > 0 || _dragOffset > 0) {
      setState(() {
        _dragOffset = (_dragOffset + delta).clamp(0, _calculatorHeight);
      });
    }
  }

  void _onCalculatorDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final progress =
        _calculatorHeight > 0 ? _dragOffset / _calculatorHeight : 0.0;

    // Calculate the current visual position as animation value
    final currentAnimValue = (1.0 - progress).clamp(0.0, 1.0);

    // Stop any ongoing animation and set to current drag position
    _calculatorController.value = currentAnimValue;

    // Reset drag state
    setState(() {
      _dragOffset = 0;
      _isDragging = false;
    });

    if (progress > 0.25 || velocity > 400) {
      // Hide with faster animation when swiped
      _calculatorController.animateTo(
        0.0,
        duration: Duration(
            milliseconds: (180 * currentAnimValue).toInt().clamp(80, 200)),
        curve: Curves.easeOut,
      );
    } else {
      // Snap back with spring-like animation
      _calculatorController.animateTo(
        1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
      );
    }
  }

  void _showAddCurrencyPicker() {
    // Check subscription limit before showing picker
    final currentCount = _displayCurrencySymbols.length;
    if (!SubscriptionManager.instance.canAddMoreCurrencies(currentCount)) {
      // Show paywall instead
      SubscriptionPaywall.show(context).then((subscribed) {
        if (subscribed && mounted) {
          setState(() {}); // Refresh UI to show add button
        }
      });
      return;
    }

    final availableCurrencies = _allCurrencies
        .where((c) =>
            !_displayCurrencySymbols.contains(c.symbol) &&
            c.id != _selectedCurrency?.id)
        .toList();

    AddCurrencyModal.show(
      context: context,
      availableCurrencies: availableCurrencies,
      onAdd: _addCurrency,
    );
  }

  Future<void> _showSettings() async {
    final lastUpdate = await _repository.getLastUpdateTime();
    final nextUpdate = _repository.getNextUpdateTime();

    if (!mounted) return;

    SettingsDialog.show(
      context: context,
      fromCache: _fromCache,
      nextUpdate: nextUpdate,
      lastUpdate: lastUpdate,
      currencyCount: _allCurrencies.length,
      onForceRefresh: () => _loadData(forceRefresh: true),
      appTheme: _appTheme,
      userCountry: _userCountry,
      userCountryFlag: _userCountryFlag,
      userCurrencyCode: _userCurrencyCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appTheme.background,
      body: _isLoading ? _buildLoadingView() : _buildMainContent(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _statusMessage,
            style: TextStyle(color: _appTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  // Public methods accessible via GlobalKey
  void refreshData() {
    AppLogger.buttonTap('refreshData (Converter)');
    _loadData(forceRefresh: true);
  }

  void showSettings() {
    AppLogger.buttonTap('showSettings (Converter)');
    _showSettings();
  }

  Widget _buildMainContent() {
    return Stack(
      children: [
        // Main scrollable content - always visible
        Column(
          children: [
            RepaintBoundary(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: InputSection(
                  key: ValueKey(_selectedCurrency?.symbol),
                  selectedCurrency: _selectedCurrency,
                  displayValue: displayValue,
                  calculatorExpression: calculatorExpression,
                  appTheme: _appTheme,
                  onTap: _showCalculator,
                ),
              ),
            ),
            Expanded(child: _buildCurrencyList()),
          ],
        ),
        // Calculator overlay with animation
        _buildCalculatorOverlay(),
      ],
    );
  }

  Widget _buildCalculatorOverlay() {
    return AnimatedBuilder(
      animation: _calculatorAnimation,
      builder: (context, child) {
        final animValue = _calculatorAnimation.value;
        // Calculate effective offset including drag
        final dragProgress = _isDragging
            ? _dragOffset / (_calculatorHeight.clamp(1, double.infinity))
            : 0.0;
        final effectiveProgress = (animValue - dragProgress).clamp(0.0, 1.0);

        if (effectiveProgress <= 0 && !_isDragging) {
          return _buildFloatingCalculatorButton();
        }

        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onVerticalDragUpdate: _onCalculatorDragUpdate,
            onVerticalDragEnd: _onCalculatorDragEnd,
            child: Transform.translate(
              offset: Offset(
                  0,
                  _isDragging
                      ? _dragOffset
                      : (1 - animValue) * _calculatorHeight),
              child: Opacity(
                opacity: effectiveProgress.clamp(0.3, 1.0),
                child: _MeasureSize(
                  onChange: (size) {
                    if (_calculatorHeight != size.height) {
                      _calculatorHeight = size.height;
                    }
                  },
                  child: CalculatorPad(
                    appTheme: _appTheme,
                    onInput: _onCalculatorInput,
                    onHide: _hideCalculator,
                    slideProgress: effectiveProgress,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingCalculatorButton() {
    final bottomPadding = DesignTokens.getBottomPadding(context);

    return Positioned(
      right: DesignTokens.space,
      bottom: bottomPadding + DesignTokens.space,
      child: GestureDetector(
        onTap: _showCalculator,
        child: Container(
          width: DesignTokens.fabSize,
          height: DesignTokens.fabSize,
          decoration: BoxDecoration(
            color: _appTheme.accent,
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            boxShadow: DesignTokens.elevatedShadow(_appTheme.accent),
          ),
          child: Icon(
            Icons.calculate_rounded,
            color: _appTheme.textPrimary,
            size: DesignTokens.iconXXL,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyList() {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.shortestSide >= 600;
    final horizontalPadding = isTablet ? 24.0 : 16.0;
    // Dynamic bottom spacing for calculator overlay
    final bottomSpacing = _calculatorHeight > 0
        ? _calculatorHeight + 20
        : (isTablet ? 100.0 : 80.0);

    // Pre-calculate conversions to avoid redundant calculations during build
    final conversions = <String, double>{};
    final exchangeRates = <String, double>{};
    if (_selectedCurrency != null) {
      for (final currency in _displayCurrencies) {
        conversions[currency.symbol] = _repository.convert(
          currentAmount,
          _selectedCurrency!,
          currency,
        );
        exchangeRates[currency.symbol] =
            _repository.convert(1.0, _selectedCurrency!, currency);
      }
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(horizontalPadding),
          sliver: SliverToBoxAdapter(
            child: _buildListHeader(),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          sliver: SliverReorderableList(
            itemBuilder: (context, index) {
              final currency = _displayCurrencies[index];
              return RepaintBoundary(
                key: ValueKey(currency.symbol),
                child: CurrencyCard(
                  currency: currency,
                  selectedCurrency: _selectedCurrency!,
                  index: index,
                  convertedAmount: conversions[currency.symbol] ?? 0.0,
                  exchangeRate: exchangeRates[currency.symbol] ?? 0.0,
                  appTheme: _appTheme,
                  onTap: () => _swapCurrency(currency, index),
                  onDismissed: () => _removeCurrency(currency),
                  onUndo: () => _addCurrency(currency),
                  formatAmount: formatAmount,
                ),
              );
            },
            itemCount: _displayCurrencies.length,
            onReorder: _onReorderCurrencies,
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                // Show upgrade widget when limit reached, otherwise add button
                if (!SubscriptionManager.instance
                    .canAddMoreCurrencies(_displayCurrencySymbols.length))
                  UpgradeToPremiumWidget(
                    message: 'Add unlimited currencies',
                    onUpgraded: () => setState(() {}),
                  )
                else
                  AddCurrencyCard(
                      appTheme: _appTheme, onTap: _showAddCurrencyPicker),
                SizedBox(height: bottomSpacing),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'CONVERTED VALUES',
          style: TextStyle(
            color: _appTheme.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        Row(
          children: [
            Icon(Icons.drag_handle, color: _appTheme.textTertiary, size: 14),
            const SizedBox(width: 4),
            Text(
              '${_displayCurrencies.length} currencies',
              style: TextStyle(color: _appTheme.textTertiary, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

/// Helper widget to measure child size
class _MeasureSize extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onChange;

  const _MeasureSize({
    required this.child,
    required this.onChange,
  });

  @override
  State<_MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<_MeasureSize> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_measureSize);
  }

  void _measureSize(_) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      widget.onChange(renderBox.size);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
