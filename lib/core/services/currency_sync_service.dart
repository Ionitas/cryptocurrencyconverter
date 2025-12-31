import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/currency.dart';
import '../../domain/repositories/currency_repository.dart';
import '../services/analytics/logging_system.dart';

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

  const SyncResult({
    required this.success,
    required this.fromCache,
    required this.message,
    required this.currencies,
    this.lastUpdated,
  });
}

/// Service for managing currency data synchronization
/// Handles cached-first approach with background updates
class CurrencySyncService extends ChangeNotifier {
  final CurrencyRepository _repository;

  // Stream controller for currency updates
  final _currencyStreamController = StreamController<List<Currency>>.broadcast();
  final _syncStateController = StreamController<SyncState>.broadcast();

  // State
  SyncState _syncState = SyncState.idle;
  List<Currency> _currencies = [];
  bool _initialLoadComplete = false;
  String _lastSyncMessage = '';
  bool _lastSyncFromCache = false;
  Timer? _backgroundSyncTimer;

  // Sync interval (15 minutes for background sync)
  static const Duration _backgroundSyncInterval = Duration(minutes: 15);

  CurrencySyncService(this._repository);

  // Getters
  Stream<List<Currency>> get currencyStream => _currencyStreamController.stream;
  Stream<SyncState> get syncStateStream => _syncStateController.stream;
  SyncState get syncState => _syncState;
  List<Currency> get currencies => _currencies;
  bool get initialLoadComplete => _initialLoadComplete;
  String get lastSyncMessage => _lastSyncMessage;
  bool get lastSyncFromCache => _lastSyncFromCache;
  bool get hasCachedData => _currencies.isNotEmpty;

  /// Initialize service - called on app start
  /// Returns cached data immediately, then syncs in background
  Future<SyncResult> initialize({bool isFirstTime = false}) async {
    AppLogger.i('SyncService', 'initialize() called - isFirstTime: $isFirstTime');

    if (isFirstTime) {
      // First time: fetch fresh data (during onboarding)
      AppLogger.i('SyncService', 'First time setup - fetching fresh data');
      return await syncNow(forceRefresh: true);
    }

    // Not first time: load from cache first
    _updateSyncState(SyncState.syncing);

    // Load cached data immediately
    AppLogger.i('SyncService', 'Loading from cache first...');
    final startTime = DateTime.now();
    final cachedResult = await _repository.loadCurrencies(forceRefresh: false);
    final loadTime = DateTime.now().difference(startTime);

    if (cachedResult.currencies.isNotEmpty) {
      _currencies = cachedResult.currencies;
      _currencyStreamController.add(_currencies);
      _initialLoadComplete = true;
      _lastSyncFromCache = cachedResult.fromCache;
      _lastSyncMessage = cachedResult.message;
      notifyListeners();

      AppLogger.s('SyncService',
          'Loaded ${_currencies.length} currencies from ${cachedResult.fromCache ? "cache" : "network"} in ${loadTime.inMilliseconds}ms');

      // If data is from cache, sync in background
      if (cachedResult.fromCache) {
        _updateSyncState(SyncState.synced);
        // Start background sync after a short delay
        AppLogger.i('SyncService', 'Scheduling background sync in 500ms...');
        Future.delayed(const Duration(milliseconds: 500), () {
          _syncInBackground();
        });
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
      );
    }

    // No cached data, fetch fresh
    AppLogger.w('SyncService', 'No cached data found, fetching fresh...');
    return await syncNow(forceRefresh: true);
  }

  /// Force sync now
  Future<SyncResult> syncNow({bool forceRefresh = false}) async {
    AppLogger.syncStart(forceRefresh ? 'Network (forced)' : 'Repository');
    final startTime = DateTime.now();
    _updateSyncState(SyncState.syncing);

    try {
      final result = await _repository.loadCurrencies(forceRefresh: forceRefresh);

      if (result.currencies.isNotEmpty) {
        _currencies = result.currencies;
        _currencyStreamController.add(_currencies);
        _initialLoadComplete = true;
        _lastSyncFromCache = result.fromCache;
        _lastSyncMessage = result.message;
        _updateSyncState(SyncState.synced);
        notifyListeners();

        final duration = DateTime.now().difference(startTime);
        AppLogger.syncComplete(
          result.fromCache ? 'Cache' : 'Network',
          _currencies.length,
          duration,
        );

        return SyncResult(
          success: true,
          fromCache: result.fromCache,
          message: result.message,
          currencies: _currencies,
          lastUpdated: await _repository.getLastUpdateTime(),
        );
      }

      AppLogger.w('SyncService', 'Sync returned empty data');
      _updateSyncState(SyncState.error);
      return SyncResult(
        success: false,
        fromCache: false,
        message: 'No data available',
        currencies: [],
      );
    } catch (e, stackTrace) {
      AppLogger.syncFailed('Repository', e);
      AppLogger.e('SyncService', 'Sync exception', error: e, stackTrace: stackTrace);
      _updateSyncState(SyncState.error);
      return SyncResult(
        success: false,
        fromCache: false,
        message: 'Sync failed: $e',
        currencies: _currencies, // Return existing cached data
      );
    }
  }

  /// Background sync (non-blocking)
  Future<void> _syncInBackground() async {
    if (_syncState == SyncState.syncing) {
      AppLogger.d('SyncService', 'Background sync skipped - already syncing');
      return;
    }

    AppLogger.background('BackgroundSync', 'Starting...');
    final startTime = DateTime.now();

    try {
      final result = await _repository.loadCurrencies(forceRefresh: true);

      if (result.currencies.isNotEmpty && !result.fromCache) {
        _currencies = result.currencies;
        _currencyStreamController.add(_currencies);
        _lastSyncFromCache = false;
        _lastSyncMessage = 'Updated in background';
        notifyListeners();

        final duration = DateTime.now().difference(startTime);
        AppLogger.background('BackgroundSync',
            'Completed - ${_currencies.length} currencies in ${duration.inMilliseconds}ms');
      } else {
        AppLogger.background('BackgroundSync', 'No new data (from cache or empty)');
      }
    } catch (e) {
      AppLogger.e('SyncService', 'Background sync failed', error: e);
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

  /// Stop background sync
  void stopBackgroundSync() {
    AppLogger.i('SyncService', 'Stopping background sync');
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = null;
  }

  void _updateSyncState(SyncState state) {
    AppLogger.d('SyncService', 'State changed: $_syncState → $state');
    _syncState = state;
    _syncStateController.add(state);
    notifyListeners();
  }

  @override
  void dispose() {
    _backgroundSyncTimer?.cancel();
    _currencyStreamController.close();
    _syncStateController.close();
    super.dispose();
  }
}
