import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FaqItem {
  const FaqItem({
    required this.qHe,
    required this.aHe,
    required this.qEn,
    required this.aEn,
  });

  final String qHe;
  final String aHe;
  final String qEn;
  final String aEn;

  String question(bool hebrew) => hebrew ? qHe : qEn;
  String answer(bool hebrew) => hebrew ? aHe : aEn;

  ({String q, String a}) pair(bool hebrew) => (q: question(hebrew), a: answer(hebrew));

  Map<String, dynamic> toJson() => {
        'qHe': qHe,
        'aHe': aHe,
        'qEn': qEn,
        'aEn': aEn,
      };

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      qHe: json['qHe'] as String? ?? '',
      aHe: json['aHe'] as String? ?? '',
      qEn: json['qEn'] as String? ?? '',
      aEn: json['aEn'] as String? ?? '',
    );
  }
}

const List<FaqItem> kDefaultFaqItems = [
  FaqItem(
    qHe: 'מה שעות הפעילות?',
    aHe: 'א׳-ה׳ 07:00-21:00, שישי עד 14:00.',
    qEn: 'What are your hours?',
    aEn: 'Sun–Thu 07:00–21:00, Fri until 14:00.',
  ),
  FaqItem(
    qHe: 'תוך כמה זמן משלוח?',
    aHe: '45-90 דקות לפי אזור ועומס.',
    qEn: 'How long is delivery?',
    aEn: '45–90 minutes depending on area and load.',
  ),
  FaqItem(
    qHe: 'איך משלמים?',
    aHe: 'אשראי, ביט או מזומן לשליח.',
    qEn: 'How can I pay?',
    aEn: 'Card, Bit, or cash to the courier.',
  ),
  FaqItem(
    qHe: 'איך עוקבים אחרי הזמנה?',
    aHe: 'בלשונית הזמנות — הזמנות בתהליך והיסטוריה.',
    qEn: 'How do I track an order?',
    aEn: 'In the Orders tab — active orders and history.',
  ),
  FaqItem(
    qHe: 'איך מבטלים הזמנה?',
    aHe: 'פנו אלינו בצ׳אט, במייל או לבעל העסק בהגדרות.',
    qEn: 'How do I cancel an order?',
    aEn: 'Contact us via chat, email, or the owner in Settings.',
  ),
  FaqItem(
    qHe: 'שאלות על אלרגנים?',
    aHe: 'כתבו לנו בפנייה ונחזור עם פירוט מדויק על המוצר.',
    qEn: 'Questions about allergens?',
    aEn: 'Message us and we will reply with exact product details.',
  ),
];

class FaqStore extends ChangeNotifier {
  FaqStore._();

  static final FaqStore instance = FaqStore._();
  static const _key = 'faq_items_v1';

  final List<FaqItem> _items = [];

  List<FaqItem> get items => List.unmodifiable(_items);

  List<({String q, String a})> displayPairs(bool hebrew) =>
      _items.map((e) => e.pair(hebrew)).toList();

  Future<void> load() async {
    _items.clear();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final e in decoded) {
            if (e is Map) {
              _items.add(FaqItem.fromJson(Map<String, dynamic>.from(e)));
            }
          }
        }
      } catch (_) {
        _items.clear();
      }
    }
    if (_items.isEmpty) {
      _items.addAll(kDefaultFaqItems);
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
    notifyListeners();
  }

  Future<void> upsertAt(int? index, FaqItem item) async {
    if (index == null) {
      _items.add(item);
    } else if (index >= 0 && index < _items.length) {
      _items[index] = item;
    }
    await _persist();
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    await _persist();
  }
}
