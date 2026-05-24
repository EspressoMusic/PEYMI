import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../saas/models/appointment_models.dart';
import 'safe_change_notifier.dart';

/// Locally saved customer phone + appointment ids for the in-app history tab.
class CustomerAppointmentsStore extends ChangeNotifier with SafeChangeNotifier {
  CustomerAppointmentsStore._();

  static final CustomerAppointmentsStore instance = CustomerAppointmentsStore._();

  static const _phoneKey = 'customer_appointment_phone';
  static const _recordsKey = 'customer_appointment_records_v1';

  String? _phone;
  final List<SaasAppointment> _records = [];

  String? get savedPhone => _phone;
  List<SaasAppointment> get records => List.unmodifiable(_records);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _phone = prefs.getString(_phoneKey);
    _records.clear();
    final raw = prefs.getString(_recordsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        for (final item in list) {
          if (item is Map) {
            _records.add(SaasAppointment.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> setPhone(String phone) async {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return;
    _phone = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phoneKey, trimmed);
    notifyListeners();
  }

  Future<void> upsertFromServer(List<SaasAppointment> list) async {
    final byId = {for (final r in _records) r.id: r};
    for (final a in list) {
      byId[a.id] = a;
    }
    _records
      ..clear()
      ..addAll(byId.values)
      ..sort((a, b) {
        final d = b.appointmentDate.compareTo(a.appointmentDate);
        if (d != 0) return d;
        return b.appointmentTime.compareTo(a.appointmentTime);
      });
    await _persist();
    notifyListeners();
  }

  Future<void> addBooking({
    required SaasAppointment appointment,
    required String customerPhone,
  }) async {
    await setPhone(customerPhone);
    final byId = {for (final r in _records) r.id: r};
    byId[appointment.id] = appointment;
    _records
      ..clear()
      ..addAll(byId.values)
      ..sort((a, b) {
        final d = b.appointmentDate.compareTo(a.appointmentDate);
        if (d != 0) return d;
        return b.appointmentTime.compareTo(a.appointmentTime);
      });
    await _persist();
    notifyListeners();
  }

  Future<void> markCancelled(String appointmentId) async {
    final i = _records.indexWhere((r) => r.id == appointmentId);
    if (i < 0) return;
    final old = _records[i];
    _records[i] = SaasAppointment(
      id: old.id,
      businessId: old.businessId,
      customerName: old.customerName,
      customerPhone: old.customerPhone,
      customerEmail: old.customerEmail,
      serviceName: old.serviceName,
      appointmentDate: old.appointmentDate,
      appointmentTime: old.appointmentTime,
      status: 'cancelled',
      notes: old.notes,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _recordsKey,
      jsonEncode(_records.map(_appointmentToJson).toList()),
    );
  }

  static Map<String, dynamic> _appointmentToJson(SaasAppointment a) => {
        'id': a.id,
        'business_id': a.businessId,
        'customer_name': a.customerName,
        'customer_phone': a.customerPhone,
        'customer_email': a.customerEmail,
        'service_name': a.serviceName,
        'appointment_date': a.appointmentDate.toIso8601String().split('T').first,
        'appointment_time': '${a.appointmentTime}:00',
        'status': a.status,
        'notes': a.notes,
      };
}
