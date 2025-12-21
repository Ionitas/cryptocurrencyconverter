import 'dart:developer' as developer;

/// Centralized logging system for the app
class LoggingSystem {
  LoggingSystem._();

  /// Log a message with the class type
  static void log(Type type, String message) {
    developer.log('[$type] $message');
  }

  /// Log an error with the class type
  static void errorLog(Type type, String message,
      [Object? error, StackTrace? stackTrace]) {
    developer.log(
      '[$type] ERROR: $message',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log a warning
  static void warningLog(Type type, String message) {
    developer.log('[$type] WARNING: $message');
  }
}
