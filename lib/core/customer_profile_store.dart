import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'community_messages_store.dart';
import 'safe_change_notifier.dart';

/// Local customer identity for orders — name + phone, persisted on device.
class CustomerProfileStore extends ChangeNotifier with SafeChangeNotifier {
  CustomerProfileStore._();

  static final CustomerProfileStore instance = CustomerProfileStore._();

  static const _nameKey = 'customer_profile_name_v1';
  static const _phoneKey = 'customer_profile_phone_v1';

  var _displayName = '';
  var _phone = '';
  var _loaded = false;

  bool get isLoaded => _loaded;

  bool get isSignedIn =>
      _displayName.trim().isNotEmpty && normalizePhone(_phone) != null;

  String get displayName => _displayName.trim();

  String get phone => _phone.trim();

  static String? normalizePhone(String? raw) {
    if (raw == null) return null;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 9 && digits.startsWith('5')) {
      return '0$digits';
    }
    if (digits.length == 10 && digits.startsWith('0')) {
      return digits;
    }
    if (digits.length >= 9 && digits.length <= 15) {
      return digits;
    }
    return null;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _displayName = prefs.getString(_nameKey) ?? '';
    final savedPhone = prefs.getString(_phoneKey) ?? '';
    _phone = normalizePhone(savedPhone) ?? savedPhone.trim();
    _loaded = true;

    if (_displayName.isNotEmpty &&
        CommunityMessagesStore.instance.displayName.trim().isEmpty) {
      await CommunityMessagesStore.instance.saveDisplayName(_displayName);
    }

    notifyListeners();
  }

  Future<void> signIn({
    required String displayName,
    required String phone,
  }) async {
    final name = displayName.trim();
    final normalized = normalizePhone(phone);
    if (name.isEmpty || normalized == null) {
      throw ArgumentError('Invalid customer profile');
    }

    _displayName = name;
    _phone = normalized;
    _loaded = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, _displayName);
    await prefs.setString(_phoneKey, _phone);
    await CommunityMessagesStore.instance.saveDisplayName(_displayName);
    notifyListeners();
  }

  Future<void> signOut() async {
    _displayName = '';
    _phone = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nameKey);
    await prefs.remove(_phoneKey);
    notifyListeners();
  }
}
