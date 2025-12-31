import 'package:flutter/foundation.dart';

import '../analytics/logging_system.dart';

/// App Lifecycle Manager
/// Manages app state transitions and coordinates services
class AppLifecycleManager {
  static AppLifecycleManager? _instance;
  static AppLifecycleManager get instance {
    _instance ??= AppLifecycleManager._();
    return _instance!;
  }

  AppLifecycleManager._();

  // App state
  bool _isInitialized = false;
  bool _isInForeground = true;
  DateTime? _backgroundedAt;
  int _sessionCount = 0;

  // Listeners
  final List<VoidCallback> _foregroundListeners = [];
  final List<VoidCallback> _backgroundListeners = [];

  // Configuration
  static const Duration _staleDataThreshold = Duration(minutes: 30);

  bool get isInitialized => _isInitialized;
  bool get isInForeground => _isInForeground;
  int get sessionCount => _sessionCount;

  /// Initialize the lifecycle manager
  void init() {
    if (_isInitialized) return;
    _isInitialized = true;
    _sessionCount++;
    AppLogger.i('Lifecycle', 'App initialized - Session #$_sessionCount');
  }

  /// Called when app comes to foreground
  void onForeground() {
    if (_isInForeground) return;

    _isInForeground = true;
    final wasBackgroundedFor = _backgroundedAt != null
        ? DateTime.now().difference(_backgroundedAt!)
        : Duration.zero;

    AppLogger.i(
        'Lifecycle', 'App foregrounded after ${wasBackgroundedFor.inSeconds}s');

    // Check if data might be stale
    final shouldRefresh = wasBackgroundedFor > _staleDataThreshold;

    // Notify listeners
    for (final listener in _foregroundListeners) {
      listener();
    }

    if (shouldRefresh) {
      AppLogger.i('Lifecycle', 'Data may be stale, triggering refresh');
      // Services will handle their own refresh logic
    }
  }

  /// Called when app goes to background
  void onBackground() {
    if (!_isInForeground) return;

    _isInForeground = false;
    _backgroundedAt = DateTime.now();
    AppLogger.i('Lifecycle', 'App backgrounded');

    // Notify listeners
    for (final listener in _backgroundListeners) {
      listener();
    }
  }

  /// Register a foreground listener
  void addForegroundListener(VoidCallback listener) {
    _foregroundListeners.add(listener);
  }

  /// Remove a foreground listener
  void removeForegroundListener(VoidCallback listener) {
    _foregroundListeners.remove(listener);
  }

  /// Register a background listener
  void addBackgroundListener(VoidCallback listener) {
    _backgroundListeners.add(listener);
  }

  /// Remove a background listener
  void removeBackgroundListener(VoidCallback listener) {
    _backgroundListeners.remove(listener);
  }

  /// Check if app was in background long enough to need refresh
  bool get shouldRefreshData {
    if (_backgroundedAt == null) return false;
    return DateTime.now().difference(_backgroundedAt!) > _staleDataThreshold;
  }

  /// Get time since last background
  Duration get timeSinceBackground {
    if (_backgroundedAt == null) return Duration.zero;
    return DateTime.now().difference(_backgroundedAt!);
  }
}
