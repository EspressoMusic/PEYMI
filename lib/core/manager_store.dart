import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'locale_translate.dart';

import 'catalog_data.dart';
import 'store_announcement.dart';

class CustomerInquiry {
  const CustomerInquiry({
    required this.id,
    required this.message,
    required this.channel,
    required this.createdAtMs,
    this.customerName,
  });

  final String id;
  final String? customerName;
  final String message;
  final String channel;
  final int createdAtMs;

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerName': customerName,
        'message': message,
        'channel': channel,
        'createdAtMs': createdAtMs,
      };

  factory CustomerInquiry.fromJson(Map<String, dynamic> json) {
    return CustomerInquiry(
      id: json['id'] as String? ?? '',
      customerName: json['customerName'] as String?,
      message: json['message'] as String? ?? '',
      channel: json['channel'] as String? ?? 'contact',
      createdAtMs: json['createdAtMs'] as int? ?? 0,
    );
  }
}

class ManagerStore extends ChangeNotifier {
  ManagerStore._();

  static final ManagerStore instance = ManagerStore._();

  static const _inquiriesKey = 'manager_inquiries';
  static const _announcementHeKey = 'manager_announcement_he';
  static const _announcementEnKey = 'manager_announcement_en';
  static const _announcementV2Key = 'manager_announcement_v2';
  static const _announcementPopupKey = 'manager_pending_announcement_popup_v1';
  static const _customDealsKey = 'manager_custom_deals';
  static const _dealAlertKey = 'manager_pending_deal_alert_v1';

  final List<CustomerInquiry> _inquiries = [];
  final List<Map<String, dynamic>> _customDeals = [];
  StoreAnnouncement _announcement = StoreAnnouncement.empty;

  List<CustomerInquiry> get inquiries => List.unmodifiable(_inquiries);
  List<Map<String, dynamic>> get customDeals => List.unmodifiable(_customDeals);

  StoreAnnouncement get storeAnnouncement => _announcement;

  String announcement(bool hebrew) => _announcement.text(hebrew);

  String get announcementImagePath => _announcement.imagePath;

  int get announcementRevision => _announcement.revision;

  bool get hasAnnouncement => _announcement.hasContent;

  List<Map<String, dynamic>> get allDeals => [
        ..._customDeals.where((d) => !CatalogData.isDealExpired(d)),
        ...CatalogData.deals.where((d) => !CatalogData.isDealExpired(d)),
      ];

  List<Map<String, dynamic>> get activeCustomDeals =>
      _customDeals.where((d) => !CatalogData.isDealExpired(d)).toList(growable: false);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    await _loadAnnouncement(prefs);

    _inquiries.clear();
    final rawInquiries = prefs.getString(_inquiriesKey);
    if (rawInquiries != null && rawInquiries.isNotEmpty) {
      final list = jsonDecode(rawInquiries) as List<dynamic>;
      for (final entry in list) {
        if (entry is Map) {
          _inquiries.add(CustomerInquiry.fromJson(Map<String, dynamic>.from(entry)));
        }
      }
      _inquiries.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
    }

    _customDeals.clear();
    final rawDeals = prefs.getString(_customDealsKey);
    if (rawDeals != null && rawDeals.isNotEmpty) {
      final list = jsonDecode(rawDeals) as List<dynamic>;
      for (final entry in list) {
        if (entry is Map) {
          _customDeals.add(Map<String, dynamic>.from(entry));
        }
      }
    }
    await pruneExpiredCustomDeals();
    notifyListeners();
  }

  Future<void> pruneExpiredCustomDeals() async {
    final before = _customDeals.length;
    _customDeals.removeWhere((d) => CatalogData.isDealExpired(d));
    if (_customDeals.length != before) {
      await _persistDeals();
      notifyListeners();
    }
  }

  Future<void> logInquiry({
    required String message,
    required String channel,
    String? customerName,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;
    _inquiries.insert(
      0,
      CustomerInquiry(
        id: 'inq_${DateTime.now().millisecondsSinceEpoch}',
        customerName: customerName,
        message: trimmed,
        channel: channel,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (_inquiries.length > 50) {
      _inquiries.removeRange(50, _inquiries.length);
    }
    await _persistInquiries();
    notifyListeners();
  }

  Future<void> _loadAnnouncement(SharedPreferences prefs) async {
    final raw = prefs.getString(_announcementV2Key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _announcement = StoreAnnouncement.fromJson(map);
        return;
      } catch (_) {}
    }
    final he = prefs.getString(_announcementHeKey) ?? '';
    final en = prefs.getString(_announcementEnKey) ?? '';
    _announcement = StoreAnnouncement(
      textHe: he,
      textEn: en,
      imagePath: '',
      revision: (he.trim().isNotEmpty || en.trim().isNotEmpty) ? 1 : 0,
    );
    if (_announcement.hasContent) {
      await _persistAnnouncement(prefs);
    }
  }

  Future<void> _persistAnnouncement([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.setString(_announcementV2Key, jsonEncode(_announcement.toJson()));
    await p.setString(_announcementHeKey, _announcement.textHe);
    await p.setString(_announcementEnKey, _announcement.textEn);
  }

  Future<void> setAnnouncement({
    required String he,
    required String en,
    String? imagePath,
    bool notifyCustomers = false,
  }) async {
    final trimmedHe = he.trim();
    final trimmedEn = en.trim();
    final img = imagePath ?? _announcement.imagePath;
    final trimmedImg = img.trim();
    final next = StoreAnnouncement(
      textHe: trimmedHe,
      textEn: trimmedEn,
      imagePath: trimmedImg,
      revision: _announcement.revision,
    );
    final publishing = notifyCustomers && next.hasContent;
    _announcement = StoreAnnouncement(
      textHe: trimmedHe,
      textEn: trimmedEn,
      imagePath: trimmedImg,
      revision: publishing ? DateTime.now().millisecondsSinceEpoch : next.revision,
    );
    await _persistAnnouncement();
    if (publishing) {
      await _queueAnnouncementPopup();
    }
    notifyListeners();
  }

  /// Manager writes once; both languages are stored for customers.
  Future<void> setAnnouncementFromText(String text, {String? imagePath}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      await setAnnouncement(he: '', en: '', imagePath: imagePath, notifyCustomers: true);
      return;
    }
    final bilingual = await LocaleTranslate.toBilingual(trimmed);
    await setAnnouncement(he: bilingual.he, en: bilingual.en, imagePath: imagePath, notifyCustomers: true);
  }

  Future<void> clearAnnouncement() async {
    _announcement = StoreAnnouncement.empty;
    final prefs = await SharedPreferences.getInstance();
    await _persistAnnouncement(prefs);
    await prefs.remove(_announcementPopupKey);
    notifyListeners();
  }

  Future<void> _queueAnnouncementPopup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_announcementPopupKey, _announcement.revision);
  }

  Future<int?> peekAnnouncementPopupRevision() async {
    final prefs = await SharedPreferences.getInstance();
    final rev = prefs.getInt(_announcementPopupKey);
    if (rev == null || rev <= 0) return null;
    if (!_announcement.hasContent || _announcement.revision != rev) return null;
    return rev;
  }

  Future<void> dismissAnnouncementPopup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_announcementPopupKey);
  }

  Future<void> queueDealAlert({required String titleHe, required String titleEn}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _dealAlertKey,
      jsonEncode({'titleHe': titleHe, 'titleEn': titleEn, 'at': DateTime.now().millisecondsSinceEpoch}),
    );
  }

  Future<({String titleHe, String titleEn})?> _readDealAlert({required bool remove}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dealAlertKey);
    if (raw == null || raw.isEmpty) return null;
    if (remove) await prefs.remove(_dealAlertKey);
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return (
        titleHe: map['titleHe'] as String? ?? '',
        titleEn: map['titleEn'] as String? ?? '',
      );
    } catch (_) {
      if (remove) await prefs.remove(_dealAlertKey);
      return null;
    }
  }

  Future<bool> hasPendingDealAlert() async => (await _readDealAlert(remove: false)) != null;

  Future<({String titleHe, String titleEn})?> peekDealAlert() => _readDealAlert(remove: false);

  Future<void> dismissDealAlert() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dealAlertKey);
  }

  Future<({String titleHe, String titleEn})?> consumeDealAlert() => _readDealAlert(remove: true);

  Future<void> addDeal({
    required String titleHe,
    required String titleEn,
    required String descHe,
    required String descEn,
    required int expiresAtMs,
    required String priceAfterDiscount,
    required List<String> images,
    required List<Map<String, dynamic>> items,
    bool notifyCustomers = false,
  }) async {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    _customDeals.insert(0, {
      'id': id,
      'titleHe': titleHe,
      'titleEn': titleEn,
      'descHe': descHe,
      'descEn': descEn,
      'validHe': CatalogData.validUntilLabel(expiresAtMs, hebrew: true),
      'validEn': CatalogData.validUntilLabel(expiresAtMs, hebrew: false),
      'expiresAtMs': expiresAtMs,
      'priceAfterDiscount': priceAfterDiscount,
      'images': images,
      'items': items,
    });
    await _persistDeals();
    if (notifyCustomers) {
      await queueDealAlert(titleHe: titleHe, titleEn: titleEn);
    }
    notifyListeners();
  }

  Future<void> removeDeal(String id) async {
    _customDeals.removeWhere((d) => d['id'] == id);
    await _persistDeals();
    notifyListeners();
  }

  Future<void> _persistInquiries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _inquiriesKey,
      jsonEncode(_inquiries.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _persistDeals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customDealsKey, jsonEncode(_customDeals));
  }
}
