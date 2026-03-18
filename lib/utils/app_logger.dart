import 'dart:developer' as developer;

/// App logger for debugging
class AppLogger {
  static const String _tag = '[SkillBid]';

  static void log(String message, [dynamic error, StackTrace? stackTrace]) {
    developer.log('$_tag [LOG] $message');
    if (error != null) {
      developer.log('$_tag [ERROR] $error');
    }
    if (stackTrace != null) {
      developer.log('$_tag [STACK] $stackTrace');
    }
  }

  static void logError(String message, [dynamic error]) {
    developer.log('$_tag [ERROR] $message', error: error);
  }

  static void logDebug(String message) {
    developer.log('$_tag [DEBUG] $message');
  }

  static void logWarning(String message) {
    developer.log('$_tag [WARNING] $message');
  }

  static void logInfo(String message) {
    developer.log('$_tag [INFO] $message');
  }
}
