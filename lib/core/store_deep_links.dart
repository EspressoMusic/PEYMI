import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';

import 'bakery_navigator.dart';
import '../saas/store_routes.dart';

/// Opens public store routes from https://bizmi.app/{slug} and bizmi:// links.
abstract final class StoreDeepLinks {
  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _subscription;

  static Future<void> init() async {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      _openRouteFromUri(initial, fromColdStart: true);
    }
    _subscription = _appLinks.uriLinkStream.listen(
      (uri) => _openRouteFromUri(uri),
    );
  }

  static void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  static void _openRouteFromUri(Uri uri, {bool fromColdStart = false}) {
    final route = storeRouteFromUri(uri);
    if (route == null) return;

    void navigate() {
      final nav = bakeryNavigatorKey.currentState;
      if (nav == null) return;
      nav.pushNamed(route);
    }

    if (fromColdStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => navigate());
    } else {
      navigate();
    }
  }
}
