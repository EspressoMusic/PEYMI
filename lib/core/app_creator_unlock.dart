/// Hidden app-creator session — password verified only on the server (Edge Function).
abstract final class AppCreatorUnlock {
  static String? _sessionPassword;

  static bool get isUnlocked =>
      _sessionPassword != null && _sessionPassword!.isNotEmpty;

  static String? get sessionPassword => _sessionPassword;

  /// Stores password after server accepted it (creator-admin / super_admin).
  static void unlockWithVerifiedPassword(String password) {
    final p = password.trim();
    if (p.isEmpty) return;
    _sessionPassword = p;
  }

  static void lock() => _sessionPassword = null;
}
