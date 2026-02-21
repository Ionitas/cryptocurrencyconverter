import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/currency.dart';
import '../../domain/repositories/currency_repository.dart';
import '../services/analytics/logging_system.dart';
import '../services/analytics/analytics_manager.dart';
import '../services/startup/app_lifecycle_manager.dart';
import '../di/injection.dart';

/// Enum representing the sync state of currency data
enum SyncState {
  idle,
  syncing,
  synced,
  error,
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final bool fromCache;
  final String message;
  final List<Currency> currencies;
  final DateTime? lastUpdated;
  final int durationMs;

  const SyncResult({
    required this.success,
    required this.fromCache,
    required this.message,
    required this.currencies,
    this.lastUpdated,
    this.durationMs = 0,
  });
}

/// Service for managing currency data synchronization
/// Handles cached-first approach with background updates
/// Optimized with debouncing, throttling, and smart caching
class CurrencySyncService extends ChangeNotifier {
  final CurrencyRepository _repository;

  // Stream controllers for reactive updates
  final _currencyStreamController =
      StreamController<List<Currency>>.broadcast();
  final _syncStateController = StreamController<SyncState>.broadcast();

  // State
  SyncState _syncState = SyncState.idle;
  List<Currency> _currencies = [];
  bool _initialLoadComplete = false;
  String _lastSyncMessage = '';
  bool _lastSyncFromCache = false;
  Timer? _backgroundSyncTimer;
  Timer? _debounceTimer;

  // Performance tracking
  int _syncCount = 0;
  int _cacheHits = 0;
  int _networkFetches = 0;

  // Sync configuration
  static const Duration _backgroundSyncInterval = Duration(minutes: 15);
  static const Duration _minSyncInterval = Duration(minutes: 5); // Throttle
  static const Duration _debounceDelay = Duration(milliseconds: 300);
  DateTime? _lastSyncTime;

  CurrencySyncService(this._repository) {
    AppLifecycleManager.instance.addForegroundListener(_onAppForeground);
    AppLifecycleManager.instance.addBackgroundListener(_onAppBackground);
  }

  /// Pause background sync when app goes to background
  void _onAppBackground() {
    if (_backgroundSyncTimer != null) {
      AppLogger.i('SyncService', 'Pausing background sync (app backgrounded)');
      _backgroundSyncTimer?.cancel();
      _backgroundSyncTimer = null;
    }
  }

  /// Resume background sync when app comes to foreground
  void _onAppForeground() {
    AppLogger.i('SyncService', 'Resuming background sync (app foregrounded)');
    if (_initialLoadComplete && _backgroundSyncTimer == null) {
      _startBackgroundSync();
    }
  }

  // Getters
  Stream<List<Currency>> get currencyStream => _currencyStreamController.stream;
  Stream<SyncState> get syncStateStream => _syncStateController.stream;
  SyncState get syncState => _syncState;
  List<Currency> get currencies => List.unmodifiable(_currencies);
  bool get initialLoadComplete => _initialLoadComplete;
  String get lastSyncMessage => _lastSyncMessage;
  bool get lastSyncFromCache => _lastSyncFromCache;
  bool get hasCachedData => _currencies.isNotEmpty;

  // Performance metrics
  Map<String, int> get performanceMetrics => {
        'sync_count': _syncCount,
        'cache_hits': _cacheHits,
        'network_fetches': _networkFetches,
        'cache_hit_rate': _syncCount > 0 ? (_cacheHits * 100 ~/ _syncCount) : 0,
      };

  /// Check if we should throttle the sync request
  bool _shouldThrottle() {
    if (_lastSyncTime == null) return false;
    final elapsed = DateTime.now().difference(_lastSyncTime!);
    return elapsed < _minSyncInterval;
  }

  /// Schedule a debounced background sync
  void _scheduleDebouncedBackgroundSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      AppLogger.i('SyncService', 'Debounced background sync triggered');
      _syncInBackground();
    });
  }

  /// Initialize service - called on app start
  /// Returns cached data immediately, then syncs in background
  Future<SyncResult> initialize({bool isFirstTime = false}) async {
    AppLogger.i(
        'SyncService', 'initialize() called - isFirstTime: $isFirstTime');

    if (isFirstTime) {
      // First time: fetch fresh data (during onboarding)
      AppLogger.i('SyncService', 'First time setup - fetching fresh data');
      return await syncNow(forceRefresh: true);
    }

    // Not first time: load from cache first (optimized)
    _updateSyncState(SyncState.syncing);

    // Load cached data immediately
    AppLogger.i('SyncService', 'Loading from cache first...');
    final startTime = DateTime.now();
    final cachedResult = await _repository.loadCurrencies(forceRefresh: false);
    final loadTime = DateTime.now().difference(startTime);
    _syncCount++;

    if (cachedResult.currencies.isNotEmpty) {
      _currencies = cachedResult.currencies;
      _currencyStreamController.add(_currencies);
      _initialLoadComplete = true;
      _lastSyncFromCache = cachedResult.fromCache;
      _lastSyncMessage = cachedResult.message;
      _lastSyncTime = DateTime.now();

      if (cachedResult.fromCache) {
        _cacheHits++;
      } else {
        _networkFetches++;
      }
      notifyListeners();

      AppLogger.s('SyncService',
          'Loaded ${_currencies.length} currencies from ${cachedResult.fromCache ? "cache" : "network"} in ${loadTime.inMilliseconds}ms');

      // Log analytics
      _logSyncAnalytics(
        source: cachedResult.fromCache ? 'cache' : 'network',
        durationMs: loadTime.inMilliseconds,
        success: true,
      );

      // If data is from cache, sync in background (debounced)
      if (cachedResult.fromCache) {
        _updateSyncState(SyncState.synced);
        _scheduleDebouncedBackgroundSync();
      } else {
        _updateSyncState(SyncState.synced);
      }

      // Start periodic background sync
      _startBackgroundSync();

      return SyncResult(
        success: true,
        fromCache: cachedResult.fromCache,
        message: cachedResult.message,
        currencies: _currencies,
        lastUpdated: await _repository.getLastUpdateTime(),
        durationMs: loadTime.inMilliseconds,
      );
    }

    // No cached data, fetch fresh
    AppLogger.w('SyncService', 'No cached data found, fetching fresh...');
    return await syncNow(forceRefresh: true);
  }

  /// Force sync now (with throttling)
  Future<SyncResult> syncNow({bool forceRefresh = false}) async {
    // Throttle non-forced requests
    if (!forceRefresh && _shouldThrottle()) {
      AppLogger.d('SyncService', 'Throttled - returning cached data');
      return SyncResult(
        success: true,
        fromCache: true,
        message: 'Using recent cache (throttled)',
        currencies: _currencies,
        lastUpdated: await _repository.getLastUpdateTime(),
      );
    }

    AppLogger.syncStart(forceRefresh ? 'Network (forced)' : 'Repository');
    final startTime = DateTime.now();
    _updateSyncState(SyncState.syncing);
    _syncCount++;

    try {
      final result =
          await _repository.loadCurrencies(forceRefresh: forceRefresh);

      if (result.currencies.isNotEmpty) {
        _currencies = result.currencies;
        _currencyStreamController.add(_currencies);
        _initialLoadComplete = true;
        _lastSyncFromCache = result.fromCache;
        _lastSyncMessage = result.message;
        _lastSyncTime = DateTime.now();

        if (result.fromCache) {
          _cacheHits++;
        } else {
          _networkFetches++;
        }

        _updateSyncState(SyncState.synced);
        notifyListeners();

        final duration = DateTime.now().difference(startTime);
        AppLogger.syncComplete(
          result.fromCache ? 'Cache' : 'Network',
          _currencies.length,
          duration,
        );

        // Log analytics
        _logSyncAnalytics(
          source: result.fromCache
              ? 'cache'
              : (forceRefresh ? 'network_forced' : 'network'),
          durationMs: duration.inMilliseconds,
          success: true,
        );

        return SyncResult(
          success: true,
          fromCache: result.fromCache,
          message: result.message,
          currencies: _currencies,
          lastUpdated: await _repository.getLastUpdateTime(),
          durationMs: duration.inMilliseconds,
        );
      }

      AppLogger.w('SyncService', 'Sync returned empty data');
      _updateSyncState(SyncState.error);
      _logSyncAnalytics(source: 'empty', durationMs: 0, success: false);
      return SyncResult(
        success: false,
        fromCache: false,
        message: 'No data available',
        currencies: [],
      );
    } catch (e, stackTrace) {
      AppLogger.syncFailed('Repository', e);
      AppLogger.e('SyncService', 'Sync exception',
          error: e, stackTrace: stackTrace);
      _updateSyncState(SyncState.error);
      _logSyncAnalytics(source: 'error', durationMs: 0, success: false);

      // Log error to analytics
      try {
        getIt<AnalyticsManager>().logError(
          errorType: 'sync_failed',
          message: e.toString(),
          stackTrace: stackTrace.toString(),
        );
      } catch (_) {}

      return SyncResult(
        success: false,
        fromCache: false,
        message: 'Sync failed: $e',
        currencies: _currencies, // Return existing cached data
      );
    }
  }

  /// Log sync analytics
  void _logSyncAnalytics({
    required String source,
    required int durationMs,
    required bool success,
  }) {
    try {
      getIt<AnalyticsManager>().logDataSync(
        source: source,
        durationMs: durationMs,
        currencyCount: _currencies.length,
        success: success,
      );
    } catch (_) {
      // Analytics not available yet
    }
  }

  /// Background sync (non-blocking, optimized)
  Future<void> _syncInBackground() async {
    if (_syncState == SyncState.syncing) {
      AppLogger.d('SyncService', 'Background sync skipped - already syncing');
      return;
    }

    // Throttle background syncs
    if (_shouldThrottle()) {
      AppLogger.d('SyncService', 'Background sync throttled');
      return;
    }

    AppLogger.background('BackgroundSync', 'Starting...');
    final startTime = DateTime.now();
    _networkFetches++;

    try {
      final result = await _repository.loadCurrencies(forceRefresh: true);

      if (result.currencies.isNotEmpty && !result.fromCache) {
        _currencies = result.currencies;
        _currencyStreamController.add(_currencies);
        _lastSyncFromCache = false;
        _lastSyncMessage = 'Updated in background';
        _lastSyncTime = DateTime.now();
        notifyListeners();

        final duration = DateTime.now().difference(startTime);
        AppLogger.background('BackgroundSync',
            'Completed - ${_currencies.length} currencies in ${duration.inMilliseconds}ms');

        _logSyncAnalytics(
          source: 'background',
          durationMs: duration.inMilliseconds,
          success: true,
        );
      } else {
        AppLogger.background(
            'BackgroundSync', 'No new data (from cache or empty)');
      }
    } catch (e) {
      AppLogger.e('SyncService', 'Background sync failed', error: e);
      _logSyncAnalytics(
          source: 'background_error', durationMs: 0, success: false);
    }
  }

  /// Start periodic background sync
  void _startBackgroundSync() {
    _backgroundSyncTimer?.cancel();
    AppLogger.i('SyncService',
        'Starting periodic background sync every ${_backgroundSyncInterval.inMinutes} minutes');
    _backgroundSyncTimer = Timer.periodic(_backgroundSyncInterval, (_) {
      AppLogger.background('PeriodicSync', 'Timer triggered');
      _syncInBackground();
    });
  }

  /// Called by the repository when a background refresh completes.
  /// Updates the currency list and notifies all listeners.
  void notifyBackgroundUpdate(List<Currency> updatedCurrencies) {
    if (updatedCurrencies.isEmpty) return;
    final startTime = _lastSyncTime ?? DateTime.now();
    AppLogger.i('SyncService',
        'Background update received: ${updatedCurrencies.length} currencies');
    _currencies = updatedCurrencies;
    _currencyStreamController.add(_currencies);
    _lastSyncFromCache = false;
    _lastSyncMessage = 'Updated in background';
    _lastSyncTime = DateTime.now();
    notifyListeners();

    // Log background sync completion analytics
    final durationMs = DateTime.now().difference(startTime).inMilliseconds;
    try {
      getIt<AnalyticsManager>().logBackgroundSyncComplete(
        currencyCount: updatedCurrencies.length,
        durationMs: durationMs,
      );
    } catch (_) {
      // Analytics not available
    }
  }

  /// Stop background sync
  void stopBackgroundSync() {
    AppLogger.i('SyncService', 'Stopping background sync');
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  void _updateSyncState(SyncState state) {
    AppLogger.d('SyncService', 'State changed: $_syncState → $state');
    _syncState = state;
    _syncStateController.add(state);
    notifyListeners();
  }

  @override
  void dispose() {
    AppLifecycleManager.instance.removeForegroundListener(_onAppForeground);
    AppLifecycleManager.instance.removeBackgroundListener(_onAppBackground);
    _backgroundSyncTimer?.cancel();
    _debounceTimer?.cancel();
    _currencyStreamController.close();
    _syncStateController.close();
    super.dispose();
  }
}
