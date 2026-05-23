import 'package:flutter/foundation.dart';

/// Debug-only logging — never prints in release/profile builds.
abstract final class AppLog {
  static void d(Object? message, [Object? detail]) {
    if (!kDebugMode) return;
    if (detail == null) {
      debugPrint(message?.toString() ?? '');
    } else {
      debugPrint('${message ?? ''}: $detail');
    }
  }

  static void w(Object? message) {
    if (!kDebugMode) return;
    debugPrint('[warn] ${message ?? ''}');
  }

  static void e(Object? message, [Object? error]) {
    if (!kDebugMode) return;
    debugPrint('[error] ${message ?? ''}${error != null ? ': $error' : ''}');
  }
}
