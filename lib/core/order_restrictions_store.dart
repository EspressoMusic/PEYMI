import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_locale.dart';
import 'business_store.dart';
import 'safe_change_notifier.dart';
import '../saas/utils/appointment_strings.dart';

enum OrderLimitPeriod { day, week }

class DayOrderHours {
  const DayOrderHours({
    required this.enabled,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  final bool enabled;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  TimeOfDay get start => TimeOfDay(hour: startHour, minute: startMinute);
  TimeOfDay get end => TimeOfDay(hour: endHour, minute: endMinute);

  DayOrderHours copyWith({
    bool? enabled,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
  }) {
    return DayOrderHours(
      enabled: enabled ?? this.enabled,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
      };

  factory DayOrderHours.fromJson(Map<String, dynamic> json) {
    return DayOrderHours(
      enabled: json['enabled'] as bool? ?? true,
      startHour: (json['startHour'] as num?)?.toInt() ?? 8,
      startMinute: (json['startMinute'] as num?)?.toInt() ?? 0,
      endHour: (json['endHour'] as num?)?.toInt() ?? 20,
      endMinute: (json['endMinute'] as num?)?.toInt() ?? 0,
    );
  }

  static DayOrderHours defaultOpen() => const DayOrderHours(
        enabled: true,
        startHour: 8,
        startMinute: 0,
        endHour: 20,
        endMinute: 0,
      );

  static DayOrderHours defaultClosed() => const DayOrderHours(
        enabled: false,
        startHour: 8,
        startMinute: 0,
        endHour: 20,
        endMinute: 0,
      );

  bool isWithinTime(DateTime t) {
    if (!enabled) return false;
    final start = startHour * 60 + startMinute;
    final end = endHour * 60 + endMinute;
    final current = t.hour * 60 + t.minute;
    if (start == end) return true;
    if (start < end) return current >= start && current <= end;
    return current >= start || current <= end;
  }
}

class OrderRestrictionsStore extends ChangeNotifier with SafeChangeNotifier {
  OrderRestrictionsStore._();

  static final OrderRestrictionsStore instance = OrderRestrictionsStore._();

  static const _prefsKey = 'order_restrictions_v3';

  bool _orderHoursEnabled = false;
  final Map<int, DayOrderHours> _dayHours = {
    for (var d = 1; d <= 7; d++) d: DayOrderHours.defaultOpen(),
  };

  bool _maxOrdersEnabled = false;
  int _maxOrders = 20;
  OrderLimitPeriod _maxOrdersPeriod = OrderLimitPeriod.day;

  static const weekdayDisplayOrder = [7, 1, 2, 3, 4, 5, 6];

  bool get orderHoursEnabled => _orderHoursEnabled;
  Set<int> get allowedWeekdays =>
      _dayHours.entries.where((e) => e.value.enabled).map((e) => e.key).toSet();

  DayOrderHours hoursForWeekday(int weekday) =>
      _dayHours[weekday] ?? DayOrderHours.defaultClosed();

  bool isDayEnabled(int weekday) => hoursForWeekday(weekday).enabled;

  /// Legacy — hours for today (manager UI compat).
  TimeOfDay get orderStartTime => hoursForWeekday(DateTime.now().weekday).start;
  TimeOfDay get orderEndTime => hoursForWeekday(DateTime.now().weekday).end;

  bool get maxOrdersEnabled => _maxOrdersEnabled;
  int get maxOrders => _maxOrders;
  OrderLimitPeriod get maxOrdersPeriod => _maxOrdersPeriod;

  bool get cutoffEnabled => _orderHoursEnabled;
  TimeOfDay get cutoffTime => orderEndTime;
  String cutoffTimeLabel(AppStrings strings) => _formatTime(orderEndTime.hour, orderEndTime.minute);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey) ??
        prefs.getString('order_restrictions_v2') ??
        prefs.getString('order_restrictions_v1');
    if (raw == null || raw.isEmpty) {
      notifyListeners();
      return;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _orderHoursEnabled = map['orderHoursEnabled'] as bool? ??
          map['cutoffEnabled'] as bool? ??
          false;

      final dayHoursRaw = map['dayHours'];
      if (dayHoursRaw is Map) {
        for (final entry in dayHoursRaw.entries) {
          final wd = int.tryParse(entry.key.toString());
          if (wd == null || wd < 1 || wd > 7) continue;
          if (entry.value is Map) {
            _dayHours[wd] = DayOrderHours.fromJson(
              Map<String, dynamic>.from(entry.value as Map),
            );
          }
        }
      } else {
        _migrateLegacyDayHours(map);
      }

      _maxOrdersEnabled = map['maxOrdersEnabled'] as bool? ?? false;
      _maxOrders = (map['maxOrders'] as num?)?.toInt() ?? 20;
      final periodRaw = map['maxOrdersPeriod'] as String? ?? 'day';
      _maxOrdersPeriod = periodRaw == 'week' ? OrderLimitPeriod.week : OrderLimitPeriod.day;
    } catch (_) {}
    _clampFields();
    notifyListeners();
  }

  void _migrateLegacyDayHours(Map<String, dynamic> map) {
    final startHour = (map['startHour'] as num?)?.toInt() ?? 8;
    final startMinute = (map['startMinute'] as num?)?.toInt() ?? 0;
    final endHour = (map['endHour'] as num?)?.toInt() ?? (map['cutoffHour'] as num?)?.toInt() ?? 20;
    final endMinute = (map['endMinute'] as num?)?.toInt() ?? (map['cutoffMinute'] as num?)?.toInt() ?? 0;
    final daysRaw = map['allowedWeekdays'] as List<dynamic>?;
    final allowed = daysRaw != null
        ? daysRaw.map((d) => (d as num).toInt()).where((d) => d >= 1 && d <= 7).toSet()
        : {1, 2, 3, 4, 5, 6, 7};
    for (var wd = 1; wd <= 7; wd++) {
      _dayHours[wd] = DayOrderHours(
        enabled: allowed.contains(wd),
        startHour: startHour,
        startMinute: startMinute,
        endHour: endHour,
        endMinute: endMinute,
      );
    }
  }

  void _clampFields() {
    for (var wd = 1; wd <= 7; wd++) {
      final h = _dayHours[wd] ?? DayOrderHours.defaultOpen();
      _dayHours[wd] = h.copyWith(
        startHour: h.startHour.clamp(0, 23),
        startMinute: h.startMinute.clamp(0, 59),
        endHour: h.endHour.clamp(0, 23),
        endMinute: h.endMinute.clamp(0, 59),
      );
    }
    if (_maxOrders < 1) _maxOrders = 1;
    if (_maxOrders > 9999) _maxOrders = 9999;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'orderHoursEnabled': _orderHoursEnabled,
        'dayHours': {
          for (final e in _dayHours.entries) '${e.key}': e.value.toJson(),
        },
        'maxOrdersEnabled': _maxOrdersEnabled,
        'maxOrders': _maxOrders,
        'maxOrdersPeriod': _maxOrdersPeriod == OrderLimitPeriod.week ? 'week' : 'day',
      }),
    );
  }

  Future<void> setOrderHoursEnabled(bool value) async {
    if (_orderHoursEnabled == value) return;
    _orderHoursEnabled = value;
    await _persist();
    notifyListeners();
  }

  Future<void> setCutoffEnabled(bool value) => setOrderHoursEnabled(value);

  Future<void> setDayEnabled(int weekday, bool enabled) async {
    if (weekday < 1 || weekday > 7) return;
    final current = hoursForWeekday(weekday);
    if (current.enabled == enabled) return;
    _dayHours[weekday] = current.copyWith(enabled: enabled);
    await _persist();
    notifyListeners();
  }

  Future<void> toggleWeekday(int weekday) async {
    final current = hoursForWeekday(weekday);
    await setDayEnabled(weekday, !current.enabled);
  }

  Future<void> setDayStartTime(int weekday, TimeOfDay time) async {
    if (weekday < 1 || weekday > 7) return;
    final current = hoursForWeekday(weekday);
    _dayHours[weekday] = current.copyWith(startHour: time.hour, startMinute: time.minute);
    _clampFields();
    await _persist();
    notifyListeners();
  }

  Future<void> setDayEndTime(int weekday, TimeOfDay time) async {
    if (weekday < 1 || weekday > 7) return;
    final current = hoursForWeekday(weekday);
    _dayHours[weekday] = current.copyWith(endHour: time.hour, endMinute: time.minute);
    _clampFields();
    await _persist();
    notifyListeners();
  }

  Future<void> setOrderStartTime(TimeOfDay time) =>
      setDayStartTime(DateTime.now().weekday, time);

  Future<void> setOrderEndTime(TimeOfDay time) => setDayEndTime(DateTime.now().weekday, time);

  Future<void> setCutoffTime(TimeOfDay time) => setOrderEndTime(time);

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

  bool isWithinOrderHours([DateTime? now]) {
    if (!_orderHoursEnabled) return true;
    final t = now ?? DateTime.now();
    return hoursForWeekday(t.weekday).isWithinTime(t);
  }

  bool isPastCutoff([DateTime? now]) => !isWithinOrderHours(now);

  int currentProductUnitCount() {
    return BusinessStore.instance.countProductUnitsInPeriod(
      week: _maxOrdersPeriod == OrderLimitPeriod.week,
    );
  }

  int remainingProductUnits({required int cartUnits}) {
    if (!_maxOrdersEnabled) return 9999;
    return (_maxOrders - currentProductUnitCount() - cartUnits).clamp(0, 9999);
  }

  String? cartUnitsBlockMessage(AppStrings strings, int cartUnits) {
    if (!isWithinOrderHours()) {
      return strings.orderBlockedOutsideHours(scheduleSummary(strings));
    }
    if (!_maxOrdersEnabled) return null;
    final used = currentProductUnitCount();
    final total = used + cartUnits;
    if (total > _maxOrders) {
      final periodLabel =
          _maxOrdersPeriod == OrderLimitPeriod.day ? strings.orderLimitPeriodDay : strings.orderLimitPeriodWeek;
      return strings.orderBlockedMaxProducts(_maxOrders, periodLabel, used, cartUnits);
    }
    return null;
  }

  String? placementBlockMessage(AppStrings strings, {int cartUnits = 0}) =>
      cartUnitsBlockMessage(strings, cartUnits);

  String scheduleSummary(AppStrings strings) {
    final parts = <String>[];
    for (final wd in weekdayDisplayOrder) {
      final day = hoursForWeekday(wd);
      if (!day.enabled) continue;
      parts.add(
        strings.orderHoursDaySchedule(
          AppointmentStrings.dayName(wd),
          _formatTime(day.startHour, day.startMinute),
          _formatTime(day.endHour, day.endMinute),
        ),
      );
    }
    if (parts.isEmpty) return strings.managerOrderHoursNone;
    return parts.join(' · ');
  }

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
