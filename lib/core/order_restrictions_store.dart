import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_locale.dart';
import 'business_store.dart';

enum OrderLimitPeriod { day, week }

class OrderRestrictionsStore extends ChangeNotifier {
  OrderRestrictionsStore._();

  static final OrderRestrictionsStore instance = OrderRestrictionsStore._();

  static const _prefsKey = 'order_restrictions_v1';

  bool _cutoffEnabled = false;
  int _cutoffHour = 18;
  int _cutoffMinute = 0;

  bool _maxOrdersEnabled = false;
  int _maxOrders = 20;
  OrderLimitPeriod _maxOrdersPeriod = OrderLimitPeriod.day;

  bool get cutoffEnabled => _cutoffEnabled;
  int get cutoffHour => _cutoffHour;
  int get cutoffMinute => _cutoffMinute;
  TimeOfDay get cutoffTime => TimeOfDay(hour: _cutoffHour, minute: _cutoffMinute);

  bool get maxOrdersEnabled => _maxOrdersEnabled;
  int get maxOrders => _maxOrders;
  OrderLimitPeriod get maxOrdersPeriod => _maxOrdersPeriod;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      notifyListeners();
      return;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _cutoffEnabled = map['cutoffEnabled'] as bool? ?? false;
      _cutoffHour = (map['cutoffHour'] as num?)?.toInt() ?? 18;
      _cutoffMinute = (map['cutoffMinute'] as num?)?.toInt() ?? 0;
      _maxOrdersEnabled = map['maxOrdersEnabled'] as bool? ?? false;
      _maxOrders = (map['maxOrders'] as num?)?.toInt() ?? 20;
      final periodRaw = map['maxOrdersPeriod'] as String? ?? 'day';
      _maxOrdersPeriod = periodRaw == 'week' ? OrderLimitPeriod.week : OrderLimitPeriod.day;
    } catch (_) {}
    _clampFields();
    notifyListeners();
  }

  void _clampFields() {
    _cutoffHour = _cutoffHour.clamp(0, 23);
    _cutoffMinute = _cutoffMinute.clamp(0, 59);
    if (_maxOrders < 1) _maxOrders = 1;
    if (_maxOrders > 9999) _maxOrders = 9999;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'cutoffEnabled': _cutoffEnabled,
        'cutoffHour': _cutoffHour,
        'cutoffMinute': _cutoffMinute,
        'maxOrdersEnabled': _maxOrdersEnabled,
        'maxOrders': _maxOrders,
        'maxOrdersPeriod': _maxOrdersPeriod == OrderLimitPeriod.week ? 'week' : 'day',
      }),
    );
  }

  Future<void> setCutoffEnabled(bool value) async {
    if (_cutoffEnabled == value) return;
    _cutoffEnabled = value;
    await _persist();
    notifyListeners();
  }

  Future<void> setCutoffTime(TimeOfDay time) async {
    _cutoffHour = time.hour;
    _cutoffMinute = time.minute;
    _clampFields();
    await _persist();
    notifyListeners();
  }

  Future<void> setMaxOrdersEnabled(bool value) async {
    if (_maxOrdersEnabled == value) return;
    _maxOrdersEnabled = value;
    await _persist();
    notifyListeners();
  }

  Future<void> setMaxOrders(int count) async {
    _maxOrders = count.clamp(1, 9999);
    await _persist();
    notifyListeners();
  }

  Future<void> setMaxOrdersPeriod(OrderLimitPeriod period) async {
    if (_maxOrdersPeriod == period) return;
    _maxOrdersPeriod = period;
    await _persist();
    notifyListeners();
  }

  bool isPastCutoff([DateTime? now]) {
    if (!_cutoffEnabled) return false;
    final t = now ?? DateTime.now();
    final cutoffMinutes = _cutoffHour * 60 + _cutoffMinute;
    final nowMinutes = t.hour * 60 + t.minute;
    return nowMinutes >= cutoffMinutes;
  }

  int currentOrderCount() {
    return BusinessStore.instance.countOrdersInPeriod(
      week: _maxOrdersPeriod == OrderLimitPeriod.week,
    );
  }

  /// Returns a localized block message, or null if placement is allowed.
  String? placementBlockMessage(AppStrings strings) {
    if (isPastCutoff()) {
      return strings.orderBlockedCutoff(_formatCutoffTime());
    }
    if (_maxOrdersEnabled) {
      final count = currentOrderCount();
      if (count >= _maxOrders) {
        final periodLabel =
            _maxOrdersPeriod == OrderLimitPeriod.day ? strings.orderLimitPeriodDay : strings.orderLimitPeriodWeek;
        return strings.orderBlockedMaxOrders(_maxOrders, periodLabel, count);
      }
    }
    return null;
  }

  String _formatCutoffTime() {
    final h = _cutoffHour.toString().padLeft(2, '0');
    final m = _cutoffMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String cutoffTimeLabel(AppStrings strings) => _formatCutoffTime();
}
