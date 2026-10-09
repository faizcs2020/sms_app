import 'package:flutter/foundation.dart';

class Logger {
  static void log(String message, {String tag = 'SMS_GATEWAY'}) {
    if (kDebugMode) {
      final now = DateTime.now().toIso8601String();
      debugPrint('[$now] [$tag] $message');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    final now = DateTime.now().toIso8601String();
    debugPrint('[$now] [ERROR] $message');
    if (error != null) debugPrint('Error details: $error');
    if (stackTrace != null) debugPrint('Stacktrace: $stackTrace');
  }
}
