import 'package:flutter/foundation.dart';

/// Unified debug logger. Never log tokens, OTPs or personal data.
abstract final class AppLogger {
  /// Logs [message] (and optional [error]) in debug builds only.
  static void log(String message, {Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[iMart] $message${error == null ? '' : ' — $error'}');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
