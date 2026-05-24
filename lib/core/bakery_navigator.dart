import 'dart:async';

import 'package:flutter/material.dart';

/// Root navigator — keeps the stack stable when theme/locale rebuilds.
final GlobalKey<NavigatorState> bakeryNavigatorKey = GlobalKey<NavigatorState>();

/// Registered from [main.dart] — opens manager home without import cycles.
Future<void> Function()? programmerOpenManagerHome;

Future<void> pushProgrammerManagerHome() async {
  final opener = programmerOpenManagerHome;
  if (opener != null) await opener();
}

/// Prefer this over a tab/sheet [BuildContext] after dialogs close.
BuildContext? get bakeryRootContext => bakeryNavigatorKey.currentContext;

NavigatorState? get bakeryNavigator => bakeryNavigatorKey.currentState;

/// Best context for showing overlays (dialogs / sheets).
BuildContext? get bakeryOverlayContext => bakeryRootContext;

/// Wait until navigator transitions and frame builds finish.
Future<void> waitForNavigatorSettle() async {
  await WidgetsBinding.instance.endOfFrame;
  await WidgetsBinding.instance.endOfFrame;
  await Future<void>.delayed(Duration.zero);
}

/// Pop on the next frame — use when no follow-up navigation is needed.
void popRouteSafely(BuildContext context, [Object? result]) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(result);
  });
}

/// Pop, wait for navigator unlock, then run [after]. Prevents `!_debugLocked`.
Future<void> popThen(
  BuildContext context,
  Future<void> Function() after, {
  Object? result,
}) {
  final completer = Completer<void>();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(result);
      }
      await waitForNavigatorSettle();
      await after();
    } finally {
      if (!completer.isCompleted) completer.complete();
    }
  });
  return completer.future;
}

Future<T?> pushRouteSafely<T>(Route<T> route) async {
  await waitForNavigatorSettle();
  final navigator = bakeryNavigator;
  if (navigator == null) return null;
  return navigator.push(route);
}

Future<T?> pushReplacementRouteSafely<T, TO>(Route<T> route, {TO? result}) async {
  await waitForNavigatorSettle();
  final navigator = bakeryNavigator;
  if (navigator == null) return null;
  return navigator.pushReplacement(route, result: result);
}

Future<T?> showOverlaySafely<T>({
  required BuildContext context,
  required Future<T?> Function(BuildContext host) show,
}) async {
  await waitForNavigatorSettle();
  final host = bakeryOverlayContext ?? context;
  if (!host.mounted) return null;
  return show(host);
}
