import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manager-facing subscription tier (local selection; billing hook later).
enum ManagerSubscriptionTier {
  none,
  premium,
  ultimate;

  static const premiumUsd = 50;
  static const ultimateUsd = 100;

  int get priceUsd => switch (this) {
        ManagerSubscriptionTier.premium => premiumUsd,
        ManagerSubscriptionTier.ultimate => ultimateUsd,
        _ => 0,
      };

  String storageKey() => name;

  static ManagerSubscriptionTier fromKey(String? raw) {
    switch (raw) {
      case 'premium':
        return ManagerSubscriptionTier.premium;
      case 'ultimate':
        return ManagerSubscriptionTier.ultimate;
      default:
        return ManagerSubscriptionTier.none;
    }
  }
}

class ManagerSubscriptionStore extends ChangeNotifier {
  ManagerSubscriptionStore._();

  static final ManagerSubscriptionStore instance = ManagerSubscriptionStore._();

  static const _prefKey = 'manager_subscription_tier_v1';

  ManagerSubscriptionTier _tier = ManagerSubscriptionTier.none;

  ManagerSubscriptionTier get tier => _tier;

  bool get hasPaidPlan =>
      _tier == ManagerSubscriptionTier.premium || _tier == ManagerSubscriptionTier.ultimate;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _tier = ManagerSubscriptionTier.fromKey(prefs.getString(_prefKey));
    notifyListeners();
  }

  Future<void> selectTier(ManagerSubscriptionTier tier) async {
    _tier = tier;
    final prefs = await SharedPreferences.getInstance();
    if (tier == ManagerSubscriptionTier.none) {
      await prefs.remove(_prefKey);
    } else {
      await prefs.setString(_prefKey, tier.storageKey());
    }
    notifyListeners();
  }
}
