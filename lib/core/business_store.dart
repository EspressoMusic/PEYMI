import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'manager_notifications_store.dart';

int parseRevenueShekels(String total) {
  final digits = total.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.isEmpty) return 0;
  return int.tryParse(digits) ?? 0;
}

class BusinessOrderLine {
  const BusinessOrderLine({required this.name, required this.quantity});

  final String name;
  final int quantity;

  Map<String, dynamic> toJson() => {'name': name, 'quantity': quantity};

  factory BusinessOrderLine.fromJson(Map<String, dynamic> json) {
    return BusinessOrderLine(
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

class BusinessOrderRecord {
  const BusinessOrderRecord({
    required this.id,
    required this.total,
    required this.summary,
    required this.createdAtMs,
    required this.revenueShekels,
    required this.lines,
  });

  final String id;
  final String total;
  final String summary;
  final int createdAtMs;
  final int revenueShekels;
  final List<BusinessOrderLine> lines;

  Map<String, dynamic> toJson() => {
        'id': id,
        'total': total,
        'summary': summary,
        'createdAtMs': createdAtMs,
        'revenueShekels': revenueShekels,
        'lines': lines.map((l) => l.toJson()).toList(),
      };

  static List<BusinessOrderLine> linesFromSummary(String summary) {
    final totals = <String, int>{};
    final qtyTail = RegExp(r'[×xX]\s*(\d+)\s*$');
    for (final raw in summary.split(' · ')) {
      final part = raw.trim();
      if (part.isEmpty) continue;
      final match = qtyTail.firstMatch(part);
      if (match != null) {
        final qty = int.tryParse(match.group(1)!) ?? 1;
        final name = part.substring(0, match.start).trim();
        if (name.isNotEmpty) {
          totals[name] = (totals[name] ?? 0) + qty;
        }
      } else {
        totals[part] = (totals[part] ?? 0) + 1;
      }
    }
    return totals.entries.map((e) => BusinessOrderLine(name: e.key, quantity: e.value)).toList();
  }

  factory BusinessOrderRecord.fromJson(Map<String, dynamic> json) {
    final total = json['total'] as String? ?? '';
    final summary = json['summary'] as String? ?? '';
    var lines = <BusinessOrderLine>[];
    final rawLines = json['lines'];
    if (rawLines is List) {
      for (final entry in rawLines) {
        if (entry is Map) {
          lines.add(BusinessOrderLine.fromJson(Map<String, dynamic>.from(entry)));
        }
      }
    }
    if (lines.isEmpty && summary.isNotEmpty) {
      lines = linesFromSummary(summary);
    }
    return BusinessOrderRecord(
      id: json['id'] as String? ?? '',
      total: total,
      summary: summary,
      createdAtMs: json['createdAtMs'] as int? ?? 0,
      revenueShekels: json['revenueShekels'] as int? ?? parseRevenueShekels(total),
      lines: lines,
    );
  }
}

class BusinessStore extends ChangeNotifier {
  BusinessStore._();

  static final BusinessStore instance = BusinessStore._();

  static const _ordersKey = 'biz_orders_count';
  static const _inquiriesKey = 'biz_inquiries_count';
  static const _reviewsKey = 'biz_reviews_count';
  static const _ordersListKey = 'biz_orders_list_v1';

  int _ordersCount = 0;
  int _inquiriesCount = 0;
  int _reviewsCount = 0;
  final List<BusinessOrderRecord> _recentOrders = [];

  int get ordersCount => _ordersCount;
  int get inquiriesCount => _inquiriesCount;
  int get reviewsCount => _reviewsCount;
  List<BusinessOrderRecord> get recentOrders => List.unmodifiable(_recentOrders);

  /// Sum of all line items across recent orders (e.g. 2 borekas + 3 borekas → 5).
  Map<String, int> get preparationTotals {
    final totals = <String, int>{};
    for (final order in _recentOrders) {
      for (final line in order.lines) {
        if (line.name.isEmpty || line.quantity <= 0) continue;
        totals[line.name] = (totals[line.name] ?? 0) + line.quantity;
      }
    }
    return totals;
  }

  int get preparationUnitCount =>
      preparationTotals.values.fold<int>(0, (sum, n) => sum + n);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _ordersCount = prefs.getInt(_ordersKey) ?? 0;
      _inquiriesCount = prefs.getInt(_inquiriesKey) ?? 0;
      _reviewsCount = prefs.getInt(_reviewsKey) ?? 0;

      _recentOrders.clear();
      final rawList = prefs.getString(_ordersListKey);
      if (rawList != null && rawList.isNotEmpty) {
        final decoded = jsonDecode(rawList);
        if (decoded is List) {
          for (final entry in decoded) {
            if (entry is Map) {
              _recentOrders.add(BusinessOrderRecord.fromJson(Map<String, dynamic>.from(entry)));
            }
          }
          _recentOrders.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
        }
      }
    } catch (_) {
      _recentOrders.clear();
    }
    notifyListeners();
  }

  Future<void> recordOrder({
    required String orderId,
    required String total,
    required String summary,
    required List<BusinessOrderLine> lines,
  }) async {
    _ordersCount++;
    final resolvedLines = lines.isNotEmpty ? lines : BusinessOrderRecord.linesFromSummary(summary);
    _recentOrders.insert(
      0,
      BusinessOrderRecord(
        id: orderId,
        total: total,
        summary: summary,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
        revenueShekels: parseRevenueShekels(total),
        lines: resolvedLines,
      ),
    );
    if (_recentOrders.length > 50) {
      _recentOrders.removeRange(50, _recentOrders.length);
    }
    await _persist(_ordersKey, _ordersCount);
    await _persistOrdersList();
    await ManagerNotificationsStore.instance.push(
      kind: ManagerNotificationKind.order,
      titleHe: 'הזמנה חדשה',
      titleEn: 'New order',
      bodyHe: '$orderId · $total',
      bodyEn: '$orderId · $total',
    );
    notifyListeners();
  }

  Future<void> recordInquiry() async {
    _inquiriesCount++;
    await _persist(_inquiriesKey, _inquiriesCount);
    await ManagerNotificationsStore.instance.push(
      kind: ManagerNotificationKind.inquiry,
      titleHe: 'פנייה מלקוח',
      titleEn: 'Customer inquiry',
      bodyHe: 'לקוח נתקל בבעיה או פנה לעזרה',
      bodyEn: 'A customer needs help or reported an issue',
    );
    notifyListeners();
  }

  Future<void> recordReview() async {
    _reviewsCount++;
    await _persist(_reviewsKey, _reviewsCount);
    await ManagerNotificationsStore.instance.push(
      kind: ManagerNotificationKind.review,
      titleHe: 'חוות דעת חדשה',
      titleEn: 'New review',
      bodyHe: 'נוספה תגובה / דירוג חדש',
      bodyEn: 'A new rating or review was added',
    );
    notifyListeners();
  }

  Future<void> _persistOrdersList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _ordersListKey,
      jsonEncode(_recentOrders.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _persist(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }
}
