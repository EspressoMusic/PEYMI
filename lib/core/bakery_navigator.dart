import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Root navigator — keeps the stack stable when theme/locale rebuilds.
final GlobalKey<NavigatorState> bakeryNavigatorKey = GlobalKey<NavigatorState>();

/// Prefer this over a tab/sheet [BuildContext] after dialogs close.
BuildContext? get bakeryRootContext => bakeryNavigatorKey.currentContext;

/// Wait until the current frame (and the next) finish — safe gap between route pops/pushes.
Future<void> waitForNavigatorSettle() async {
  await WidgetsBinding.instance.endOfFrame;
  await WidgetsBinding.instance.endOfFrame;
}

/// Pop a dialog/route on the next frame so the overlay tree is not mid-teardown.
void popRouteSafely(BuildContext context, [Object? result]) {
  SchedulerBinding.instance.scheduleFrameCallback((_) {
    if (!context.mounted) return;
    Navigator.of(context).pop(result);
  });
}
