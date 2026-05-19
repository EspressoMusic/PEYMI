import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_locale.dart';

class CommunityMessage {
  const CommunityMessage({
    required this.authorHe,
    required this.authorEn,
    required this.textHe,
    required this.textEn,
    required this.createdAtMs,
  });

  final String authorHe;
  final String authorEn;
  final String textHe;
  final String textEn;
  final int createdAtMs;

  String author(bool he) => he ? authorHe : authorEn;
  String text(bool he) => he ? textHe : textEn;

  Map<String, dynamic> toJson() => {
        'authorHe': authorHe,
        'authorEn': authorEn,
        'textHe': textHe,
        'textEn': textEn,
        'createdAtMs': createdAtMs,
      };

  factory CommunityMessage.fromJson(Map<String, dynamic> json) {
    return CommunityMessage(
      authorHe: json['authorHe'] as String? ?? '',
      authorEn: json['authorEn'] as String? ?? '',
      textHe: json['textHe'] as String? ?? '',
      textEn: json['textEn'] as String? ?? '',
      createdAtMs: json['createdAtMs'] as int? ?? 0,
    );
  }
}

class CommunityMessagesStore extends ChangeNotifier {
  CommunityMessagesStore._();

  static final CommunityMessagesStore instance = CommunityMessagesStore._();
  static const _key = 'community_messages_v1';

  final List<CommunityMessage> _messages = [];

  List<CommunityMessage> get messages => List.unmodifiable(_messages);

  Future<void> load() async {
    _messages.clear();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final e in decoded) {
            if (e is Map) {
              _messages.add(CommunityMessage.fromJson(Map<String, dynamic>.from(e)));
            }
          }
          _messages.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
        }
      } catch (_) {
        _messages.clear();
      }
    }
    if (_messages.isEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      _messages.addAll([
        CommunityMessage(
          authorHe: 'נועה',
          authorEn: 'Noa',
          textHe: 'הבורקס מדהים! תודה על השירות החם.',
          textEn: 'The bourekas are amazing! Thanks for the warm service.',
          createdAtMs: now - 86400000,
        ),
        CommunityMessage(
          authorHe: 'עומר',
          authorEn: 'Omer',
          textHe: 'הזמנה דרך האפליקציה הייתה קלה ומהירה.',
          textEn: 'Ordering through the app was easy and fast.',
          createdAtMs: now - 172800000,
        ),
      ]);
      await _persist();
    }
    notifyListeners();
  }

  Future<void> post({required String author, required String text}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final he = AppLocale.instance.isHebrew;
    final name = author.trim().isEmpty ? (he ? 'אורח' : 'Guest') : author.trim();
    _messages.insert(
      0,
      CommunityMessage(
        authorHe: he ? name : name,
        authorEn: he ? name : name,
        textHe: he ? trimmed : '',
        textEn: he ? '' : trimmed,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_messages.map((m) => m.toJson()).toList()));
  }
}
