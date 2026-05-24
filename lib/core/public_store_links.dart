import '../saas/utils/slug_utils.dart';

/// Shareable public store URLs (e.g. https://espressomusic.github.io/PEYMI/{slug}).
/// Override at build time: --dart-define=PUBLIC_STORE_BASE_URL=...
abstract final class PublicStoreLinks {
  static const baseUrl = String.fromEnvironment(
    'PUBLIC_STORE_BASE_URL',
    defaultValue: 'https://bizmi.app',
  );

  static Uri get baseUri {
    final trimmed = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse(trimmed.isEmpty ? 'https://bizmi.app' : trimmed);
  }

  static String get host => baseUri.host;

  /// Path prefix on hosts like GitHub Pages, e.g. `/PEYMI` for `…/PEYMI/shiki`.
  static String get publicPathPrefix {
    final path = baseUri.path.replaceAll(RegExp(r'/+$'), '');
    return path.isEmpty || path == '/' ? '' : path;
  }

  static bool hostMatches(String? linkHost) {
    if (linkHost == null || linkHost.isEmpty) return false;
    final h = linkHost.toLowerCase();
    final primary = host.toLowerCase();
    return h == primary || h == 'www.$primary';
  }

  /// Full HTTPS link for sharing (never a bare "/slug").
  static String publicUrlForSlug(String slug) {
    final normalized = normalizeSlug(slug);
    return '${baseUri.toString()}/$normalized';
  }

  /// In-app route used by [Navigator] (internal).
  static String internalRouteForSlug(String slug) => '/${normalizeSlug(slug)}';
}
