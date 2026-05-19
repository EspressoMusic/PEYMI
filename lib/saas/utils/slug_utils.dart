/// Client-side slug preview — server normalizes and validates uniqueness.
String normalizeSlug(String input) {
  var s = input.trim().toLowerCase();
  s = s.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
  s = s.replaceAll(RegExp(r'\s+'), '-');
  s = s.replaceAll(RegExp(r'-+'), '-');
  s = s.replaceAll(RegExp(r'^-|-$'), '');
  return s;
}
