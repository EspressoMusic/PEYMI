import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'demo_store.dart';
import 'manager_notifications_store.dart';
import 'safe_change_notifier.dart';

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
  static const statusPending = 'pending';
  static const statusApproved = 'approved';

  const BusinessOrderRecord({
    required this.id,
    required this.total,
    required this.summary,
    required this.createdAtMs,
    required this.revenueShekels,
    required this.lines,
    this.status = statusPending,
  });

  final String id;
  final String total;
  final String summary;
  final int createdAtMs;
  final int revenueShekels;
  final List<BusinessOrderLine> lines;
  final String status;

  bool get isPending => status == statusPending;
  bool get isApproved => status == statusApproved;

  BusinessOrderRecord copyWith({String? status}) {
    return BusinessOrderRecord(
      id: id,
      total: total,
      summary: summary,
      createdAtMs: createdAtMs,
      revenueShekels: revenueShekels,
      lines: lines,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'total': total,
        'summary': summary,
        'createdAtMs': createdAtMs,
        'revenueShekels': revenueShekels,
        'lines': lines.map((l) => l.toJson()).toList(),
        'status': status,
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
      status: json['status'] as String? ?? BusinessOrderRecord.statusPending,
    );
  }
}

class BusinessStore extends ChangeNotifier with SafeChangeNotifier {
  BusinessStore._();

  static final BusinessStore instance = BusinessStore._();

  static const _legacyOrdersKey = 'biz_orders_count';
  static const _legacyInquiriesKey = 'biz_inquiries_count';
  static const _legacyReviewsKey = 'biz_reviews_count';
  static const _legacyOrdersListKey = 'biz_orders_list_v1';

  String? _loadedSlug;
  int _ordersCount = 0;
  int _inquiriesCount = 0;
  int _reviewsCount = 0;
  final List<BusinessOrderRecord> _recentOrders = [];

  static String _ordersKeyFor(String slug) => 'biz_orders_count_$slug';
  static String _inquiriesKeyFor(String slug) => 'biz_inquiries_count_$slug';
  static String _reviewsKeyFor(String slug) => 'biz_reviews_count_$slug';
  static String _ordersListKeyFor(String slug) => 'biz_orders_list_v1_$slug';

  int get ordersCount => _ordersCount;
  int get inquiriesCount => _inquiriesCount;
  int get reviewsCount => _reviewsCount;
  List<BusinessOrderRecord> get recentOrders => List.unmodifiable(_recentOrders);

  List<BusinessOrderRecord> get pendingOrders =>
      _recentOrders.where((o) => o.isPending).toList(growable: false);

  List<BusinessOrderRecord> get approvedOrders =>
      _recentOrders.where((o) => o.isApproved).toList(growable: false);

  /// Sum of line items across pending orders only (manager prep dashboard).
  Map<String, int> get preparationTotals {
    final totals = <String, int>{};
    for (final order in pendingOrders) {
      for (final line in order.lines) {
        if (line.name.isEmpty || line.quantity <= 0) continue;
        totals[line.name] = (totals[line.name] ?? 0) + line.quantity;
      }
    }
    return totals;
  }

  int get preparationUnitCount =>
      preparationTotals.values.fold<int>(0, (sum, n) => sum + n);

  /// Orders recorded since start of today or this week (Monday, local calendar).
  int countOrdersInPeriod({required bool week, DateTime? now}) {
    final t = now ?? DateTime.now();
    final start = week ? _startOfWeek(t) : DateTime(t.year, t.month, t.day);
    final startMs = start.millisecondsSinceEpoch;
    return _recentOrders.where((o) => o.createdAtMs >= startMs).length;
  }

  /// Product units (line quantities) from orders in the period.
  int countProductUnitsInPeriod({required bool week, DateTime? now}) {
    final t = now ?? DateTime.now();
    final start = week ? _startOfWeek(t) : DateTime(t.year, t.month, t.day);
    final startMs = start.millisecondsSinceEpoch;
    var units = 0;
    for (final order in _recentOrders) {
      if (order.createdAtMs < startMs) continue;
      for (final line in order.lines) {
        if (line.quantity > 0) units += line.quantity;
      }
    }
    return units;
  }

  static DateTime _startOfWeek(DateTime date) {
    final weekday = date.weekday;
    final monday = date.subtract(Duration(days: weekday - DateTime.monday));
    return DateTime(monday.year, monday.month, monday.day);
  }

  Future<void> load() async => loadForCurrentStore(null);

  Future<void> loadForCurrentStore(String? slug) async {
    final normalized = slug?.trim().toLowerCase();
    _loadedSlug = (normalized != null && normalized.isNotEmpty) ? normalized : null;
    _ordersCount = 0;
    _inquiriesCount = 0;
    _reviewsCount = 0;
    _recentOrders.clear();

    final storeSlug = _loadedSlug;
    if (storeSlug == null) {
      notifyListeners();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await _maybeMigrateLegacy(prefs, storeSlug);

      _ordersCount = prefs.getInt(_ordersKeyFor(storeSlug)) ?? 0;
      _inquiriesCount = prefs.getInt(_inquiriesKeyFor(storeSlug)) ?? 0;
      _reviewsCount = prefs.getInt(_reviewsKeyFor(storeSlug)) ?? 0;

      final rawList = prefs.getString(_ordersListKeyFor(storeSlug));
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

  Future<void> _maybeMigrateLegacy(SharedPreferences prefs, String slug) async {
    if (!DemoStore.isDemoSlug(slug)) return;
    if (prefs.containsKey(_ordersListKeyFor(slug))) return;
    final legacyList = prefs.getString(_legacyOrdersListKey);
    if (legacyList == null || legacyList.isEmpty) return;
    await prefs.setString(_ordersListKeyFor(slug), legacyList);
    final legacyCount = prefs.getInt(_legacyOrdersKey);
    if (legacyCount != null) await prefs.setInt(_ordersKeyFor(slug), legacyCount);
    final legacyInquiries = prefs.getInt(_legacyInquiriesKey);
    if (legacyInquiries != null) await prefs.setInt(_inquiriesKeyFor(slug), legacyInquiries);
    final legacyReviews = prefs.getInt(_legacyReviewsKey);
    if (legacyReviews != null) await prefs.setInt(_reviewsKeyFor(slug), legacyReviews);
  }

  Future<void> recordOrder({
    required String orderId,
    required String total,
    required String summary,
    String? customerName,
    String? customerPhone,
    required List<BusinessOrderLine> lines,
  }) async {
    if (_loadedSlug == null) return;
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
    await _persist(_ordersKeyFor(_loadedSlug!), _ordersCount);
    await _persistOrdersList();
    final customerBit = (customerName?.trim().isNotEmpty == true || customerPhone?.trim().isNotEmpty == true)
        ? ' · ${customerName?.trim() ?? ''}${customerPhone != null && customerPhone.trim().isNotEmpty ? ' · ${customerPhone.trim()}' : ''}'
        : '';
    await ManagerNotificationsStore.instance.push(
      kind: ManagerNotificationKind.order,
      titleHe: 'הזמנה חדשה',
      titleEn: 'New order',
      bodyHe: '$orderId · $total$customerBit',
      bodyEn: '$orderId · $total$customerBit',
    );
    notifyListeners();
  }

  Future<bool> approveOrder(String orderId) async {
    final index = _recentOrders.indexWhere((o) => o.id == orderId);
    if (index < 0) return false;
    final order = _recentOrders[index];
    if (!order.isPending) return false;
    _recentOrders[index] = order.copyWith(status: BusinessOrderRecord.statusApproved);
    await _persistOrdersList();
    notifyListeners();
    return true;
  }

  Future<int> approveAllPendingOrders() async {
    var count = 0;
    for (var i = 0; i < _recentOrders.length; i++) {
      if (!_recentOrders[i].isPending) continue;
      _recentOrders[i] = _recentOrders[i].copyWith(status: BusinessOrderRecord.statusApproved);
      count++;
    }
    if (count > 0) {
      await _persistOrdersList();
      notifyListeners();
    }
    return count;
  }

  Future<int> clearApprovedOrders() async {
    final before = _recentOrders.length;
    _recentOrders.removeWhere((o) => o.isApproved);
    final removed = before - _recentOrders.length;
    if (removed > 0) {
      await _persistOrdersList();
      notifyListeners();
    }
    return removed;
  }

  Future<void> recordInquiry() async {
    if (_loadedSlug == null) return;
    _inquiriesCount++;
    await _persist(_inquiriesKeyFor(_loadedSlug!), _inquiriesCount);
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
    if (_loadedSlug == null) return;
    _reviewsCount++;
    await _persist(_reviewsKeyFor(_loadedSlug!), _reviewsCount);
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
    final slug = _loadedSlug;
    if (slug == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _ordersListKeyFor(slug),
      jsonEncode(_recentOrders.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _persist(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }
}
