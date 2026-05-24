import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../saas/data/saas_repository.dart';
import '../saas/models/appointment_models.dart';
import 'order_restrictions_store.dart';
import 'safe_change_notifier.dart';
import 'supabase/supabase_bootstrap.dart';

/// Appointment-mode schedule: weekly active hours + slot duration (synced to Supabase when linked).
class AppointmentScheduleStore extends ChangeNotifier with SafeChangeNotifier {
  AppointmentScheduleStore._();

  static final AppointmentScheduleStore instance = AppointmentScheduleStore._();

  static const _prefsKeyPrefix = 'appointment_schedule_v1_';

  final Map<int, DayOrderHours> _dayHours = {
    for (final w in OrderRestrictionsStore.weekdayDisplayOrder) w: DayOrderHours.defaultClosed(),
  };

  var _slotDurationMinutes = 30;
  var _loaded = false;
  String? _loadedBusinessId;

  bool get isLoaded => _loaded;
  int get slotDurationMinutes => _slotDurationMinutes;

  static List<int> get weekdayDisplayOrder => OrderRestrictionsStore.weekdayDisplayOrder;

  DayOrderHours hoursForWeekday(int weekday) => _dayHours[weekday] ?? DayOrderHours.defaultClosed();

  Future<void> load({String? businessId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefsKeyPrefix${businessId ?? 'local'}';
    final raw = prefs.getString(key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _slotDurationMinutes = (map['slotDurationMinutes'] as num?)?.toInt() ?? 30;
        final days = map['days'] as Map<String, dynamic>? ?? {};
        for (final entry in days.entries) {
          final w = int.tryParse(entry.key);
          if (w == null) continue;
          _dayHours[w] = DayOrderHours.fromJson(Map<String, dynamic>.from(entry.value as Map));
        }
      } catch (_) {
        _applyDefaults();
      }
    } else {
      _applyDefaults();
    }

    _loadedBusinessId = businessId;
    if (SupabaseBootstrap.isReady && businessId != null && businessId.isNotEmpty) {
      try {
        final settings = await SaasRepository.instance.fetchAppointmentSettings(businessId);
        if (settings != null) {
          _slotDurationMinutes = settings.slotDurationMinutes;
        }
        final rows = await SaasRepository.instance.fetchBusinessAvailability(businessId);
        if (rows.isNotEmpty) {
          for (final w in weekdayDisplayOrder) {
            _dayHours[w] = DayOrderHours.defaultClosed();
          }
          for (final row in rows) {
            final flutterDay = BusinessAvailabilityRow.pgDayToFlutter(row.dayOfWeek);
            final parts = row.startTime.split(':');
            final endParts = row.endTime.split(':');
            _dayHours[flutterDay] = DayOrderHours(
              enabled: row.isActive,
              startHour: int.parse(parts[0]),
              startMinute: int.parse(parts[1]),
              endHour: int.parse(endParts[0]),
              endMinute: int.parse(endParts[1]),
            );
          }
          await _persistLocal(businessId);
        }
      } catch (_) {}
    }

    _loaded = true;
    notifyListeners();
  }

  void _applyDefaults() {
    for (final w in weekdayDisplayOrder) {
      final open = w == DateTime.sunday || (w >= DateTime.monday && w <= DateTime.thursday);
      _dayHours[w] = open
          ? const DayOrderHours(enabled: true, startHour: 9, startMinute: 0, endHour: 17, endMinute: 0)
          : DayOrderHours.defaultClosed();
    }
    _slotDurationMinutes = 30;
  }

  Future<void> setDayEnabled(int weekday, bool enabled) async {
    _dayHours[weekday] = hoursForWeekday(weekday).copyWith(enabled: enabled);
    notifyListeners();
    await _save();
  }

  Future<void> setDayStartTime(int weekday, TimeOfDay time) async {
    _dayHours[weekday] = hoursForWeekday(weekday).copyWith(
      startHour: time.hour,
      startMinute: time.minute,
    );
    notifyListeners();
    await _save();
  }

  Future<void> setDayEndTime(int weekday, TimeOfDay time) async {
    _dayHours[weekday] = hoursForWeekday(weekday).copyWith(
      endHour: time.hour,
      endMinute: time.minute,
    );
    notifyListeners();
    await _save();
  }

  Future<void> setSlotDurationMinutes(int minutes) async {
    final clamped = minutes.clamp(10, 240);
    if (_slotDurationMinutes == clamped) return;
    _slotDurationMinutes = clamped;
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final businessId = _loadedBusinessId;
    await _persistLocal(businessId);
    if (!SupabaseBootstrap.isReady || businessId == null || businessId.isEmpty) return;
    try {
      await SaasRepository.instance.updateAppointmentSettings(
        businessId: businessId,
        slotDurationMinutes: _slotDurationMinutes,
      );
      final rows = <BusinessAvailabilityRow>[];
      for (final w in weekdayDisplayOrder) {
        final day = hoursForWeekday(w);
        rows.add(
          BusinessAvailabilityRow(
            dayOfWeek: BusinessAvailabilityRow.flutterWeekdayToPg(w),
            startTime: _formatTime(day.start),
            endTime: _formatTime(day.end),
            isActive: day.enabled,
          ),
        );
      }
      await SaasRepository.instance.replaceBusinessAvailability(
        businessId: businessId,
        rows: rows,
      );
    } catch (_) {}
  }

  Future<void> _persistLocal(String? businessId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefsKeyPrefix${businessId ?? 'local'}';
    final days = <String, dynamic>{
      for (final e in _dayHours.entries) '${e.key}': e.value.toJson(),
    };
    await prefs.setString(
      key,
      jsonEncode({
        'slotDurationMinutes': _slotDurationMinutes,
        'days': days,
      }),
    );
  }

  static String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }
}
