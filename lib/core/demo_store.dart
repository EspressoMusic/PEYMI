/// Public demo store used when no online business is linked yet.
abstract final class DemoStore {
  static const slug = String.fromEnvironment(
    'DEMO_STORE_SLUG',
    defaultValue: 'shilo',
  );

  /// Previous demo slug — still accepted for login and deep links.
  static const legacySlug = 'shiki';

  static const managerPin = '1234';

  /// Default inbox for the public demo store.
  static const defaultContactEmail = 'shilohdhd1@gmail.com';

  static bool isDemoSlug(String? value) {
    if (value == null) return false;
    final normalized = value.trim().toLowerCase();
    if (normalized == 'shilo' || normalized == 'shiki') return true;
    return normalized == slug.toLowerCase() || normalized == legacySlug;
  }

  /// Slugs to try when loading demo business from Supabase.
  static List<String> get serverSlugs => [slug, legacySlug];
}
