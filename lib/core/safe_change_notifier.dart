import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'bakery_navigator.dart';

/// Defers [ChangeNotifier.notifyListeners] until after the frame and any
/// in-flight navigator transitions — prevents `_dependents.isEmpty` crashes.
mixin SafeChangeNotifier on ChangeNotifier {
  var _notifyQueued = false;

  @override
  void notifyListeners() {
    scheduleNotifyListeners();
  }

  void scheduleNotifyListeners() {
    if (_notifyQueued) return;
    _notifyQueued = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _notifyQueued = false;
        await waitForNavigatorSettle();
        if (hasListeners) {
          super.notifyListeners();
        }
      });
    });
  }

  /// Use sparingly — only when no overlay route is opening/closing.
  void notifyListenersNow() {
    if (hasListeners) super.notifyListeners();
  }
}
