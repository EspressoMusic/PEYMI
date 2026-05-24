import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_locale.dart';
import 'demo_store.dart';
import 'safe_change_notifier.dart';

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

class CommunityMessagesStore extends ChangeNotifier with SafeChangeNotifier {
  CommunityMessagesStore._();

  static final CommunityMessagesStore instance = CommunityMessagesStore._();
  static const _legacyKey = 'community_messages_v1';

  static String _keyFor(String slug) => 'community_messages_v1_$slug';

  String? _loadedSlug;

  final List<CommunityMessage> _messages = [];
  static const _namePrefKey = 'community_display_name_v1';

  String _displayName = '';

  List<CommunityMessage> get messages => List.unmodifiable(_messages);

  /// Oldest first — natural chat order (scroll to latest at bottom).
  List<CommunityMessage> get messagesChronological {
    final copy = List<CommunityMessage>.from(_messages);
    copy.sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));
    return copy;
  }

  String get displayName => _displayName;

  Future<void> load() async => loadForCurrentStore(null);

  Future<void> loadForCurrentStore(String? slug) async {
    final normalized = slug?.trim().toLowerCase();
    _loadedSlug = (normalized != null && normalized.isNotEmpty) ? normalized : null;
    _messages.clear();

    final storeSlug = _loadedSlug;
    if (storeSlug == null) {
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    _displayName = prefs.getString(_namePrefKey) ?? '';
    var raw = prefs.getString(_keyFor(storeSlug));
    if ((raw == null || raw.isEmpty) && DemoStore.isDemoSlug(storeSlug)) {
      final legacy = prefs.getString(_legacyKey);
      if (legacy != null && legacy.isNotEmpty) {
        raw = legacy;
        await prefs.setString(_keyFor(storeSlug), legacy);
      }
    }

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
    if (_messages.isEmpty && DemoStore.isDemoSlug(storeSlug)) {
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

  Future<void> saveDisplayName(String name) async {
    _displayName = name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_namePrefKey, _displayName);
    notifyListeners();
  }

  Future<void> post({required String author, required String text}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final he = AppLocale.instance.isHebrew;
    final typed = author.trim();
    if (typed.isNotEmpty) {
      await saveDisplayName(typed);
    }
    final name = typed.isNotEmpty
        ? typed
        : (_displayName.isNotEmpty ? _displayName : (he ? 'אורח' : 'Guest'));
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
    final slug = _loadedSlug;
    if (slug == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(slug), jsonEncode(_messages.map((m) => m.toJson()).toList()));
  }
}
