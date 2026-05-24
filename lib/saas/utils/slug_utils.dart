/// Client-side slug preview — server normalizes and validates uniqueness.
String normalizeSlug(String input) {
  var s = input.trim().toLowerCase();
  s = s.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
  s = s.replaceAll(RegExp(r'\s+'), '-');
  s = s.replaceAll(RegExp(r'-+'), '-');
  s = s.replaceAll(RegExp(r'^-|-$'), '');
  return s;
}

/// Slugs that must not be used as public store paths.
const storeReservedSlugs = <String>{
  'super-admin',
  'settings',
  'orders',
  'deals',
  'catalog',
  'www',
};

bool slugIsReserved(String slug) => storeReservedSlugs.contains(normalizeSlug(slug));
