import 'package:flutter/material.dart';

import '../core/public_store_links.dart';
import '../core/supabase/supabase_bootstrap.dart';
import 'screens/public_store_screen.dart';
import 'utils/slug_utils.dart';
import 'widgets/super_admin_gate.dart';

const storeReservedSlugs = <String>{
  'super-admin',
  'settings',
  'orders',
  'deals',
  'catalog',
  'www',
};

/// Parses https://bizmi.app/{slug}, bizmi://{slug}, or /{slug}.
String? storeSlugFromUri(Uri uri) {
  if (uri.scheme == 'bizmi') {
    if (uri.host.isNotEmpty) return _validSlug(uri.host);
    if (uri.pathSegments.isNotEmpty) return _validSlug(uri.pathSegments.first);
    return null;
  }

  if (uri.scheme == 'http' || uri.scheme == 'https') {
    if (!PublicStoreLinks.hostMatches(uri.host)) return null;
    return storeSlugFromPath(uri.path);
  }

  if (uri.scheme.isEmpty && uri.path.isNotEmpty) {
    return storeSlugFromPath(uri.path);
  }

  return null;
}

String? storeSlugFromPath(String path) {
  var p = path.trim();
  if (p.isEmpty || p == '/') return null;
  if (!p.startsWith('/')) p = '/$p';

  final prefix = PublicStoreLinks.publicPathPrefix;
  if (prefix.isNotEmpty && (p == prefix || p.startsWith('$prefix/'))) {
    p = p.substring(prefix.length);
    if (p.isEmpty) p = '/';
  }

  if (p.contains('/', 1)) return null;
  return _validSlug(p.substring(1));
}

String? _validSlug(String raw) {
  final slug = normalizeSlug(raw);
  if (slug.isEmpty || storeReservedSlugs.contains(slug)) return null;
  return slug;
}

/// Navigator route name for a public store, e.g. "/shiki".
String? storeRouteFromUri(Uri uri) {
  final slug = storeSlugFromUri(uri);
  if (slug == null) return null;
  return PublicStoreLinks.internalRouteForSlug(slug);
}

Route<dynamic>? saasRouteFactory(RouteSettings settings) {
  final path = settings.name ?? '/';
  if (path == '/super-admin') {
    if (!SupabaseBootstrap.isReady) return null;
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const SuperAdminGate(),
    );
  }
  if (path.startsWith('/') && path.length > 2 && !path.contains('/', 1)) {
    final slug = path.substring(1).toLowerCase();
    if (!storeReservedSlugs.contains(slug) && SupabaseBootstrap.isReady) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => PublicStoreScreen(slug: slug),
      );
    }
  }
  return null;
}
