import 'package:shared_preferences/shared_preferences.dart';

/// Locally remembers manager panel PIN for a linked store slug (device only).
class ManagerCredentialsStore {
  ManagerCredentialsStore._();

  static final ManagerCredentialsStore instance = ManagerCredentialsStore._();

  static const _rememberKey = 'manager_pin_remember_v1';
  static const _slugKey = 'manager_pin_slug_v1';
  static const _pinKey = 'manager_pin_value_v1';

  Future<({String slug, String pin})?> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_rememberKey) ?? false)) return null;
    final slug = prefs.getString(_slugKey)?.trim();
    final pin = prefs.getString(_pinKey);
    if (slug == null || slug.isEmpty || pin == null || pin.isEmpty) return null;
    return (slug: slug, pin: pin);
  }

  Future<void> save({required String slug, required String pin, required bool remember}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!remember) {
      await clear();
      return;
    }
    await prefs.setBool(_rememberKey, true);
    await prefs.setString(_slugKey, slug.trim().toLowerCase());
    await prefs.setString(_pinKey, pin);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberKey);
    await prefs.remove(_slugKey);
    await prefs.remove(_pinKey);
  }

  static const _ownerEmailKey = 'owner_auth_email_v1';
  static const _ownerRememberEmailKey = 'owner_auth_remember_email_v1';

  Future<String?> loadRememberedOwnerEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_ownerRememberEmailKey) ?? false)) return null;
    return prefs.getString(_ownerEmailKey);
  }

  Future<void> saveRememberedOwnerEmail({required String email, required bool remember}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!remember) {
      await prefs.remove(_ownerRememberEmailKey);
      await prefs.remove(_ownerEmailKey);
      return;
    }
    await prefs.setBool(_ownerRememberEmailKey, true);
    await prefs.setString(_ownerEmailKey, email.trim());
  }
}
