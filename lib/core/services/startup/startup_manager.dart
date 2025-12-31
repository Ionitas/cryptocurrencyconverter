import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../analytics/logging_system.dart';
import '../analytics/firebase_analytics_service.dart';

/// App Startup Manager
/// Handles optimized parallel initialization of services
class StartupManager {
  static StartupManager? _instance;
  static StartupManager get instance {
    _instance ??= StartupManager._();
    return _instance!;
  }

  StartupManager._();

  final Stopwatch _startupTimer = Stopwatch();
  final Map<String, Duration> _initTimes = {};

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Critical services that must complete before app starts
  final List<Future<void> Function()> _criticalTasks = [];

  /// Non-critical services that can run after app starts
  final List<Future<void> Function()> _deferredTasks = [];

  /// Register a critical task (blocks app startup)
  void registerCriticalTask(String name, Future<void> Function() task) {
    _criticalTasks.add(() async {
      final timer = Stopwatch()..start();
      try {
        await task();
        timer.stop();
        _initTimes[name] = timer.elapsed;
        AppLogger.s(
            'Startup', '$name completed in ${timer.elapsedMilliseconds}ms');
      } catch (e) {
        timer.stop();
        _initTimes[name] = timer.elapsed;
        AppLogger.e(
            'Startup', '$name failed after ${timer.elapsedMilliseconds}ms',
            error: e);
      }
    });
  }

  /// Register a deferred task (runs after app starts)
  void registerDeferredTask(String name, Future<void> Function() task) {
    _deferredTasks.add(() async {
      final timer = Stopwatch()..start();
      try {
        await task();
        timer.stop();
        _initTimes[name] = timer.elapsed;
        AppLogger.d('Startup',
            'Deferred: $name completed in ${timer.elapsedMilliseconds}ms');
      } catch (e) {
        timer.stop();
        AppLogger.e('Startup', 'Deferred: $name failed', error: e);
      }
    });
  }

  /// Run all critical tasks in parallel
  Future<void> runCriticalTasks() async {
    _startupTimer.start();
    AppLogger.i(
        'Startup', 'Starting ${_criticalTasks.length} critical tasks...');

    // Run all critical tasks in parallel for faster startup
    await Future.wait(_criticalTasks.map((task) => task()));

    _startupTimer.stop();
    AppLogger.s('Startup',
        'Critical tasks completed in ${_startupTimer.elapsedMilliseconds}ms');

    _isInitialized = true;
    _logStartupMetrics();
  }

  /// Run deferred tasks after app has started
  Future<void> runDeferredTasks() async {
    if (_deferredTasks.isEmpty) return;

    AppLogger.i(
        'Startup', 'Running ${_deferredTasks.length} deferred tasks...');

    // Run deferred tasks sequentially to avoid overwhelming the system
    for (final task in _deferredTasks) {
      await task();
      // Small delay between deferred tasks
      await Future.delayed(const Duration(milliseconds: 100));
    }

    AppLogger.s('Startup', 'All deferred tasks completed');
  }

  /// Log startup performance metrics to analytics
  void _logStartupMetrics() {
    final metrics = <String, Object>{
      'total_startup_ms': _startupTimer.elapsedMilliseconds,
      'platform': Platform.operatingSystem,
    };

    // Add individual task times
    _initTimes.forEach((name, duration) {
      metrics['${name}_ms'] = duration.inMilliseconds;
    });

    FirebaseAnalyticsService.instance.logEvent(
      name: 'app_startup_performance',
      parameters: metrics,
    );

    if (kDebugMode) {
      print('=== Startup Performance ===');
      print('Total: ${_startupTimer.elapsedMilliseconds}ms');
      _initTimes.forEach((name, duration) {
        print('  $name: ${duration.inMilliseconds}ms');
      });
      print('===========================');
    }
  }

  /// Get startup duration
  Duration get startupDuration => _startupTimer.elapsed;

  /// Get individual task times
  Map<String, Duration> get taskTimes => Map.unmodifiable(_initTimes);

  /// Reset for testing
  void reset() {
    _criticalTasks.clear();
    _deferredTasks.clear();
    _initTimes.clear();
    _startupTimer.reset();
    _isInitialized = false;
  }
}
