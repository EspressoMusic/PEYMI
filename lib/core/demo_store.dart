/// Public demo store used when no online business is linked yet.
abstract final class DemoStore {
  static const slug = String.fromEnvironment(
    'DEMO_STORE_SLUG',
    defaultValue: 'shiki',
  );

  static bool isDemoSlug(String? value) =>
      value != null && value.trim().toLowerCase() == slug.toLowerCase();
}
