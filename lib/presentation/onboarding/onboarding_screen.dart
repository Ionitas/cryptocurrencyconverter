import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/di/injection.dart';
import '../../core/services/onboarding_service.dart';
import '../../core/services/geolocation_service.dart';
import '../../core/services/currency_sync_service.dart';
import '../../core/services/subscription/subscription_service.dart';
import '../../core/services/analytics/analytics_manager.dart';
import 'welcome_page.dart';
import 'features_page.dart';
import 'country_selection_page.dart';
import 'purpose_selection_page.dart';
import 'paywall_page.dart';

/// Main onboarding screen controller
/// 5 pages: Welcome -> Features -> Country -> Purpose -> Paywall
/// Progress bar only shows for last 3 pages (Country, Purpose, Paywall)
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final AppTheme _appTheme = getIt<AppTheme>();
  final OnboardingService _onboardingService = OnboardingService();
  final GeoLocationService _geoService = GeoLocationService();
  final CurrencySyncService _syncService = getIt<CurrencySyncService>();

  late PageController _pageController;
  late AnimationController _progressController;

  // Total pages: 0=Welcome, 1=Features, 2=Country, 3=Purpose, 4=Paywall
  static const int _totalPages = 5;
  static const int _countryPageIndex = 2;

  int _currentPage = 0;
  CountryInfo? _detectedCountry;
  CountryInfo? _selectedCountry;
  UserPurpose? _selectedPurpose;
  bool _locationDetectionComplete = false;
  bool _dataFetchStarted = false;
  bool _dataLoaded = false;
  int _loadedCurrencyCount = 0;
  String _loadingStatus = 'Preparing...';

  // Analytics timing
  late DateTime _onboardingStartTime;
  DateTime _stepStartTime = DateTime.now();

  // Default country if detection fails
  static const CountryInfo _defaultCountry = CountryInfo(
    name: 'United States',
    code: 'US',
    flag: '🇺🇸',
  );

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Analytics: record onboarding start time
    _onboardingStartTime = DateTime.now();
    _stepStartTime = DateTime.now();

    // Log onboarding begin
    getIt<AnalyticsManager>().logOnboardingBegin();

    // Start background location detection and data fetch immediately
    _detectLocationInBackground();
    _fetchDataInBackground();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  /// Fetch currency data in background during onboarding
  Future<void> _fetchDataInBackground() async {
    if (_dataFetchStarted) return;
    _dataFetchStarted = true;

    try {
      if (mounted) {
        setState(() {
          _loadingStatus = 'Fetching exchange rates...';
        });
      }

      // Initialize sync service with isFirstTime=true to fetch fresh data
      final result = await _syncService.initialize(isFirstTime: true);

      if (mounted) {
        setState(() {
          _dataLoaded = result.success;
          _loadedCurrencyCount = result.currencies.length;
          _loadingStatus = result.success
              ? '${result.currencies.length} currencies loaded'
              : 'Ready to go';
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch data during onboarding: $e');
      if (mounted) {
        setState(() {
          _loadingStatus = 'Will sync when ready';
        });
      }
      // Continue even if failed - will retry later
    }
  }

  /// Detect location in background with timeout
  Future<void> _detectLocationInBackground() async {
    try {
      // Race between actual detection and timeout
      final result = await Future.any([
        _geoService.detectCountryFromIP(),
        Future.delayed(const Duration(seconds: 3), () => null),
      ]);

      if (mounted) {
        setState(() {
          _detectedCountry = result ?? _defaultCountry;
          _locationDetectionComplete = true;
        });
      }
    } catch (e) {
      // On any error, use default country
      if (mounted) {
        setState(() {
          _detectedCountry = _defaultCountry;
          _locationDetectionComplete = true;
        });
      }
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutQuart,
      );
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutQuart,
      );
    }
  }

  void _onCountrySelected(CountryInfo country) {
    setState(() {
      _selectedCountry = country;
    });

    // Log country selection with auto-detect status
    getIt<AnalyticsManager>().logOnboardingCountrySelected(
      countryCode: country.code,
      countryName: country.name,
      wasAutoDetected: _detectedCountry?.code == country.code,
    );

    _goToNextPage();
  }

  void _onPurposeSelected(UserPurpose purpose) {
    setState(() {
      _selectedPurpose = purpose;
    });

    // Log purpose selection
    getIt<AnalyticsManager>().logOnboardingPurposeSelected(
      purpose: purpose.name,
    );

    // Check if user already has an active subscription
    // If so, skip the paywall and complete onboarding
    _checkSubscriptionAndProceed();
  }

  Future<void> _checkSubscriptionAndProceed() async {
    try {
      final subscriptionService = SubscriptionService.instance;

      // Initialize subscription service if needed to check status
      if (!subscriptionService.isInitialized) {
        await subscriptionService.init();
      }

      // If user is already premium, skip paywall
      if (subscriptionService.isPremium) {
        _completeOnboarding();
        return;
      }
    } catch (e) {
      // If we can't check subscription status, show paywall anyway
      debugPrint('Could not check subscription status: $e');
    }

    // Show paywall for non-premium users
    _goToNextPage();
  }

  Future<void> _completeOnboarding() async {
    // Log onboarding complete (standard GA4 event)
    getIt<AnalyticsManager>().logOnboardingComplete();

    // Log onboarding complete with timing data
    final totalDuration = DateTime.now().difference(_onboardingStartTime);
    getIt<AnalyticsManager>().logOnboardingCompleteTimed(
      totalDurationSeconds: totalDuration.inSeconds,
      countryCode: _selectedCountry?.code,
      purpose: _selectedPurpose?.name,
    );

    // Save onboarding data
    await _onboardingService.saveOnboardingData(
      OnboardingData(
        country: _selectedCountry?.name,
        countryCode: _selectedCountry?.code,
        purpose: _selectedPurpose,
        completed: true,
      ),
    );

    // Set user country in analytics
    if (_selectedCountry != null) {
      getIt<AnalyticsManager>().setUserCountry(_selectedCountry!.code);
    }

    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = _appTheme.currentTheme == ThemeOption.light;

    // Update system UI
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          isLightTheme ? Brightness.dark : Brightness.light,
      statusBarBrightness: isLightTheme ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: _appTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator and back button (only show for pages 2-4)
            if (_currentPage >= _countryPageIndex) _buildHeader(),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  // Log timing for the page we're leaving
                  final stepDuration =
                      DateTime.now().difference(_stepStartTime);
                  final previousStepNames = {
                    0: 'welcome',
                    1: 'features',
                    2: 'country_selection',
                    3: 'purpose_selection',
                    4: 'paywall',
                  };
                  if (_currentPage < _totalPages) {
                    getIt<AnalyticsManager>().logOnboardingStepWithTiming(
                      stepNumber: _currentPage,
                      stepName: previousStepNames[_currentPage] ?? 'unknown',
                      durationMs: stepDuration.inMilliseconds,
                    );
                  }

                  // Reset timer for new step
                  _stepStartTime = DateTime.now();

                  setState(() {
                    _currentPage = page;
                  });
                  // Log onboarding step analytics
                  final stepNames = {
                    0: 'welcome',
                    1: 'features',
                    2: 'country_selection',
                    3: 'purpose_selection',
                    4: 'paywall',
                  };
                  getIt<AnalyticsManager>().logOnboardingStep(
                    stepNumber: page,
                    stepName: stepNames[page] ?? 'unknown',
                  );
                },
                children: [
                  // Page 0: Welcome
                  WelcomePage(
                    appTheme: _appTheme,
                    onContinue: _goToNextPage,
                    isDataLoading: _dataFetchStarted && !_dataLoaded,
                    loadingStatus: _loadingStatus,
                    currencyCount: _loadedCurrencyCount,
                  ),

                  // Page 1: Features
                  FeaturesPage(
                    appTheme: _appTheme,
                    onContinue: _goToNextPage,
                  ),

                  // Page 2: Country Selection
                  CountrySelectionPage(
                    appTheme: _appTheme,
                    suggestedCountry:
                        _locationDetectionComplete ? _detectedCountry : null,
                    onCountrySelected: _onCountrySelected,
                  ),

                  // Page 3: Purpose Selection
                  PurposeSelectionPage(
                    appTheme: _appTheme,
                    onPurposeSelected: _onPurposeSelected,
                  ),

                  // Page 4: Paywall
                  PaywallPage(
                    appTheme: _appTheme,
                    onClose: _completeOnboarding,
                    onSubscribe: () {
                      // Subscription was successful
                      _completeOnboarding();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Progress is for pages 2-4 (index 0-2 in the 3-stage progress)
    final progressIndex = _currentPage - _countryPageIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _goToPreviousPage();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _appTheme.surfaceLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _appTheme.textSecondary,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Progress indicator (3 stages)
          Expanded(child: _buildProgressIndicator(progressIndex)),

          const SizedBox(width: 16),

          // Page counter
          Text(
            '${progressIndex + 1}/3',
            style: TextStyle(
              color: _appTheme.textTertiary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(int progressIndex) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 8,
        decoration: BoxDecoration(
          color: _appTheme.surfaceLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: List.generate(3, (index) {
            final isActive = index <= progressIndex;

            return Expanded(
              child: Container(
                margin: EdgeInsets.only(left: index > 0 ? 4 : 0),
                decoration: BoxDecoration(
                  color: isActive
                      ? _appTheme.primary
                      : _appTheme.surfaceLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: _appTheme.primary.withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
