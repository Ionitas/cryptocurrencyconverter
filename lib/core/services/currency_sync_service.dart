import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/currency.dart';
import '../../domain/repositories/currency_repository.dart';

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
    if (isFirstTime) {
      // First time: fetch fresh data (during onboarding)
      return await syncNow(forceRefresh: true);
    }

    // Not first time: load from cache first
    _updateSyncState(SyncState.syncing);

    // Load cached data immediately
    final cachedResult = await _repository.loadCurrencies(forceRefresh: false);

    if (cachedResult.currencies.isNotEmpty) {
      _currencies = cachedResult.currencies;
      _currencyStreamController.add(_currencies);
      _initialLoadComplete = true;
      _lastSyncFromCache = cachedResult.fromCache;
      _lastSyncMessage = cachedResult.message;
      notifyListeners();

      // If data is from cache, sync in background
      if (cachedResult.fromCache) {
        _updateSyncState(SyncState.synced);
        // Start background sync after a short delay
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
    return await syncNow(forceRefresh: true);
  }

  /// Force sync now
  Future<SyncResult> syncNow({bool forceRefresh = false}) async {
    _updateSyncState(SyncState.syncing);

    try {
      final result =
          await _repository.loadCurrencies(forceRefresh: forceRefresh);

      if (result.currencies.isNotEmpty) {
        _currencies = result.currencies;
        _currencyStreamController.add(_currencies);
        _initialLoadComplete = true;
        _lastSyncFromCache = result.fromCache;
        _lastSyncMessage = result.message;
        _updateSyncState(SyncState.synced);
        notifyListeners();

        return SyncResult(
          success: true,
          fromCache: result.fromCache,
          message: result.message,
          currencies: _currencies,
          lastUpdated: await _repository.getLastUpdateTime(),
        );
      }

      _updateSyncState(SyncState.error);
      return SyncResult(
        success: false,
        fromCache: false,
        message: 'No data available',
        currencies: [],
      );
    } catch (e) {
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
    if (_syncState == SyncState.syncing) return;

    try {
      final result = await _repository.loadCurrencies(forceRefresh: true);

      if (result.currencies.isNotEmpty && !result.fromCache) {
        _currencies = result.currencies;
        _currencyStreamController.add(_currencies);
        _lastSyncFromCache = false;
        _lastSyncMessage = 'Updated in background';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Background sync failed: $e');
    }
  }

  /// Start periodic background sync
  void _startBackgroundSync() {
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = Timer.periodic(_backgroundSyncInterval, (_) {
      _syncInBackground();
    });
  }

  /// Stop background sync
  void stopBackgroundSync() {
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = null;
  }

  void _updateSyncState(SyncState state) {
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
