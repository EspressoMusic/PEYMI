import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'safe_change_notifier.dart';

/// Who must accept the privacy policy on first entry.
enum PolicyAudience {
  customer,
  owner,
}

/// Tracks one-time (per version) policy acceptance for customers and business owners.
class PolicyConsentStore extends ChangeNotifier with SafeChangeNotifier {
  PolicyConsentStore._();

  static final PolicyConsentStore instance = PolicyConsentStore._();

  static const policyVersion = 2;
  static const _customerKey = 'policy_consent_customer_v$policyVersion';
  static const _ownerKey = 'policy_consent_owner_v$policyVersion';

  /// Optional explainer video (pass via --dart-define=POLICY_VIDEO_URL=...).
  static const policyVideoUrl = String.fromEnvironment('POLICY_VIDEO_URL');

  var _customerAccepted = false;
  var _ownerAccepted = false;
  var _loaded = false;

  bool get isLoaded => _loaded;

  bool hasAccepted(PolicyAudience audience) {
    switch (audience) {
      case PolicyAudience.customer:
        return _customerAccepted;
      case PolicyAudience.owner:
        return _ownerAccepted;
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _customerAccepted = prefs.getBool(_customerKey) ?? false;
    _ownerAccepted = prefs.getBool(_ownerKey) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> accept(PolicyAudience audience) async {
    switch (audience) {
      case PolicyAudience.customer:
        _customerAccepted = true;
      case PolicyAudience.owner:
        _ownerAccepted = true;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      audience == PolicyAudience.customer ? _customerKey : _ownerKey,
      true,
    );
    notifyListeners();
  }
}
