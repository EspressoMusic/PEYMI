import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'safe_change_notifier.dart';

enum ManagerNotificationKind { order, review, inquiry, problem }

class ManagerNotification {
  const ManagerNotification({
    required this.id,
    required this.kind,
    required this.titleHe,
    required this.titleEn,
    required this.bodyHe,
    required this.bodyEn,
    required this.createdAtMs,
    this.read = false,
  });

  final String id;
  final ManagerNotificationKind kind;
  final String titleHe;
  final String titleEn;
  final String bodyHe;
  final String bodyEn;
  final int createdAtMs;
  final bool read;

  String title(bool hebrew) => hebrew ? titleHe : titleEn;
  String body(bool hebrew) => hebrew ? bodyHe : bodyEn;

  ManagerNotification copyWith({bool? read}) => ManagerNotification(
        id: id,
        kind: kind,
        titleHe: titleHe,
        titleEn: titleEn,
        bodyHe: bodyHe,
        bodyEn: bodyEn,
        createdAtMs: createdAtMs,
        read: read ?? this.read,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'titleHe': titleHe,
        'titleEn': titleEn,
        'bodyHe': bodyHe,
        'bodyEn': bodyEn,
        'createdAtMs': createdAtMs,
        'read': read,
      };

  factory ManagerNotification.fromJson(Map<String, dynamic> json) {
    return ManagerNotification(
      id: json['id'] as String? ?? '',
      kind: ManagerNotificationKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => ManagerNotificationKind.problem,
      ),
      titleHe: json['titleHe'] as String? ?? '',
      titleEn: json['titleEn'] as String? ?? '',
      bodyHe: json['bodyHe'] as String? ?? '',
      bodyEn: json['bodyEn'] as String? ?? '',
      createdAtMs: json['createdAtMs'] as int? ?? 0,
      read: json['read'] as bool? ?? false,
    );
  }
}

class ManagerNotificationsStore extends ChangeNotifier with SafeChangeNotifier {
  ManagerNotificationsStore._();

  static final ManagerNotificationsStore instance = ManagerNotificationsStore._();
  static const _storageKey = 'manager_notifications_v1';

  final List<ManagerNotification> _items = [];

  List<ManagerNotification> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((n) => !n.read).length;

  Future<void> load() async {
    _items.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final entry in decoded) {
            if (entry is Map) {
              _items.add(ManagerNotification.fromJson(Map<String, dynamic>.from(entry)));
            }
          }
          _items.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
        }
      }
    } catch (_) {
      _items.clear();
    }
    notifyListeners();
  }

  Future<void> push({
    required ManagerNotificationKind kind,
    required String titleHe,
    required String titleEn,
    required String bodyHe,
    required String bodyEn,
  }) async {
    _items.insert(
      0,
      ManagerNotification(
        id: 'ntf_${DateTime.now().millisecondsSinceEpoch}',
        kind: kind,
        titleHe: titleHe,
        titleEn: titleEn,
        bodyHe: bodyHe,
        bodyEn: bodyEn,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (_items.length > 40) {
      _items.removeRange(40, _items.length);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    final i = _items.indexWhere((n) => n.id == id);
    if (i < 0) return;
    _items[i] = _items[i].copyWith(read: true);
    await _persist();
    notifyListeners();
  }

  Future<void> markAllRead() async {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(read: true);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }
}
