import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Log levels for categorizing log messages
enum LogLevel {
  debug,
  info,
  warning,
  error,
  success,
}

/// Centralized logging system for the app
/// All logs are printed to debug console and can be filtered by level
class AppLogger {
  AppLogger._();

  static bool _enabled = kDebugMode;

  /// Enable or disable logging globally
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Get formatted timestamp
  static String get _timestamp {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}.'
        '${now.millisecond.toString().padLeft(3, '0')}';
  }

  /// Get emoji prefix for log level
  static String _levelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.success:
        return '✅';
    }
  }

  /// Core logging method
  static void _log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_enabled) return;

    final prefix = _levelPrefix(level);
    final formattedMessage = '$prefix [$_timestamp] [$tag] $message';

    developer.log(
      formattedMessage,
      name: tag,
      error: error,
      stackTrace: stackTrace,
      level: level == LogLevel.error ? 1000 : 800,
    );

    // Also print to console for visibility
    if (kDebugMode) {
      debugPrint(formattedMessage);
      if (error != null) {
        debugPrint('   Error: $error');
      }
    }
  }

  /// Log debug message
  static void d(String tag, String message) {
    _log(LogLevel.debug, tag, message);
  }

  /// Log info message
  static void i(String tag, String message) {
    _log(LogLevel.info, tag, message);
  }

  /// Log warning message
  static void w(String tag, String message) {
    _log(LogLevel.warning, tag, message);
  }

  /// Log error message
  static void e(String tag, String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, tag, message, error: error, stackTrace: stackTrace);
  }

  /// Log success message
  static void s(String tag, String message) {
    _log(LogLevel.success, tag, message);
  }

  /// Log a sync operation start
  static void syncStart(String source) {
    i('SYNC', '▶ Starting sync from $source...');
  }

  /// Log a sync operation complete
  static void syncComplete(String source, int count, Duration duration) {
    s('SYNC', '◀ Sync complete from $source: $count items in ${duration.inMilliseconds}ms');
  }

  /// Log a sync operation failure
  static void syncFailed(String source, Object error) {
    e('SYNC', '◀ Sync failed from $source', error: error);
  }

  /// Log a button tap
  static void buttonTap(String buttonName) {
    d('UI', '👆 Button tapped: $buttonName');
  }

  /// Log a network request
  static void networkRequest(String endpoint) {
    d('NETWORK', '→ Request: $endpoint');
  }

  /// Log a network response
  static void networkResponse(String endpoint, int statusCode, Duration duration) {
    if (statusCode >= 200 && statusCode < 300) {
      s('NETWORK', '← Response: $endpoint [$statusCode] in ${duration.inMilliseconds}ms');
    } else {
      w('NETWORK', '← Response: $endpoint [$statusCode] in ${duration.inMilliseconds}ms');
    }
  }

  /// Log cache operation
  static void cache(String operation, String key, {bool hit = true}) {
    final emoji = hit ? '💾' : '💨';
    d('CACHE', '$emoji $operation: $key (${hit ? 'HIT' : 'MISS'})');
  }

  /// Log background task
  static void background(String taskName, String status) {
    i('BACKGROUND', '🔄 $taskName: $status');
  }
}

/// Legacy compatibility - redirects to AppLogger
class LoggingSystem {
  LoggingSystem._();

  static void log(Type type, String message) {
    AppLogger.i(type.toString(), message);
  }

  static void errorLog(Type type, String message, [Object? error, StackTrace? stackTrace]) {
    AppLogger.e(type.toString(), message, error: error, stackTrace: stackTrace);
  }

  static void warningLog(Type type, String message) {
    AppLogger.w(type.toString(), message);
  }
}
