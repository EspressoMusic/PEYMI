import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'locale_translate.dart';

import '../saas/data/saas_repository.dart';
import 'catalog_data.dart';
import 'catalog_image_storage.dart';
import 'demo_store.dart';
import 'email_validation.dart';
import 'store_announcement.dart';
import 'store_scoped_reload.dart';
import 'push/deal_push_service.dart';
import 'supabase/supabase_bootstrap.dart';
import 'safe_change_notifier.dart';

class CustomerInquiry {
  const CustomerInquiry({
    required this.id,
    required this.message,
    required this.channel,
    required this.createdAtMs,
    this.customerName,
    this.customerPhone,
    this.reason,
    this.replyText,
    this.replyAtMs,
    this.replySeenByCustomer = true,
  });

  final String id;
  final String? customerName;
  final String? customerPhone;
  final String? reason;
  final String message;
  final String channel;
  final int createdAtMs;
  final String? replyText;
  final int? replyAtMs;
  final bool replySeenByCustomer;

  bool get hasReply => replyText?.trim().isNotEmpty == true;

  CustomerInquiry copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? reason,
    String? message,
    String? channel,
    int? createdAtMs,
    String? replyText,
    int? replyAtMs,
    bool? replySeenByCustomer,
  }) {
    return CustomerInquiry(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      reason: reason ?? this.reason,
      message: message ?? this.message,
      channel: channel ?? this.channel,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      replyText: replyText ?? this.replyText,
      replyAtMs: replyAtMs ?? this.replyAtMs,
      replySeenByCustomer: replySeenByCustomer ?? this.replySeenByCustomer,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'reason': reason,
        'message': message,
        'channel': channel,
        'createdAtMs': createdAtMs,
        if (replyText != null) 'replyText': replyText,
        if (replyAtMs != null) 'replyAtMs': replyAtMs,
        'replySeenByCustomer': replySeenByCustomer,
      };

  factory CustomerInquiry.fromJson(Map<String, dynamic> json) {
    return CustomerInquiry(
      id: json['id'] as String? ?? '',
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      reason: json['reason'] as String?,
      message: json['message'] as String? ?? '',
      channel: json['channel'] as String? ?? 'app',
      createdAtMs: json['createdAtMs'] as int? ?? 0,
      replyText: json['replyText'] as String?,
      replyAtMs: json['replyAtMs'] as int?,
      replySeenByCustomer: json['replySeenByCustomer'] as bool? ?? true,
    );
  }
}

class ManagerStore extends ChangeNotifier with SafeChangeNotifier {
  ManagerStore._();

  static final ManagerStore instance = ManagerStore._();

  /// Alias kept for call sites — same as deferred [notifyListeners].
  void notifyListenersDeferred() => scheduleNotifyListeners();

  static const _inquiriesKey = 'manager_inquiries';
  static const _inquiriesLastSeenKey = 'manager_inquiries_last_seen_v1';
  static const _announcementHeKey = 'manager_announcement_he';
  static const _announcementEnKey = 'manager_announcement_en';
  static const _announcementV2Key = 'manager_announcement_v2';
  static const _announcementPopupKey = 'manager_pending_announcement_popup_v1';
  static const _customDealsKey = 'manager_custom_deals';
  static const _hiddenBuiltinDealsKey = 'manager_hidden_builtin_deals_v1';
  static const _dealAlertKey = 'manager_pending_deal_alert_v1';
  static const _linkedSlugKey = 'manager_online_business_slug';
  static const _linkedIdKey = 'manager_online_business_id';
  static const _customerPanelModeKey = 'manager_customer_panel_mode';
  static const _storeModeChosenKey = 'manager_store_mode_chosen_v1';
  static const _storeAppImagePathKey = 'manager_store_app_image_path';
  static const _storeAppLogoUrlKey = 'manager_store_app_logo_url';
  static const _storeContactEmailKey = 'manager_store_contact_email_v1';

  final List<CustomerInquiry> _inquiries = [];
  int _inquiriesLastSeenAtMs = 0;
  final List<Map<String, dynamic>> _customDeals = [];
  final Set<String> _hiddenBuiltinDealIds = {};
  StoreAnnouncement _announcement = StoreAnnouncement.empty;
  String? _linkedBusinessSlug;
  String? _linkedBusinessId;
  String _customerPanelMode = 'products';
  String _storeAppImagePath = '';
  String? _storeAppLogoUrl;
  String? _storeContactEmail;

  /// What customers see in the app menu: catalog or appointment booking.
  String get customerPanelMode => _customerPanelMode;

  bool get isAppointmentCustomerMode => _customerPanelMode == 'appointments';

  bool get hasLinkedBusiness =>
      _linkedBusinessSlug != null && _linkedBusinessSlug!.trim().isNotEmpty;

  String? get linkedBusinessSlug => _linkedBusinessSlug;

  String? get linkedBusinessId => _linkedBusinessId;

  String get storeAppImagePath => _storeAppImagePath;

  String? get storeAppLogoUrl => _storeAppLogoUrl;

  String? get storeContactEmail =>
      _storeContactEmail?.trim().isNotEmpty == true ? _storeContactEmail!.trim() : null;

  /// Inquiry inbox — saved store email, or demo default for [DemoStore].
  String? get effectiveContactEmail {
    final saved = storeContactEmail;
    if (saved != null) return saved;
    if (DemoStore.isDemoSlug(_linkedBusinessSlug)) return DemoStore.defaultContactEmail;
    return null;
  }

  bool get hasOnlineLinkedBusiness =>
      _linkedBusinessId != null &&
      _linkedBusinessId!.isNotEmpty &&
      _linkedBusinessId != 'local';

  /// Customer checkout — only after opening a real store (not demo / preview).
  bool get canCustomerPlaceOrders =>
      hasOnlineLinkedBusiness && !DemoStore.isDemoSlug(_linkedBusinessSlug);

  bool get hasStoreAppBranding =>
      (_storeAppLogoUrl != null && _storeAppLogoUrl!.trim().isNotEmpty) ||
      _storeAppImagePath.trim().isNotEmpty;

  List<CustomerInquiry> get inquiries => List.unmodifiable(_inquiries);

  bool get hasUnreadInquiries =>
      _inquiries.any((inquiry) => inquiry.createdAtMs > _inquiriesLastSeenAtMs);
  List<Map<String, dynamic>> get customDeals => List.unmodifiable(_customDeals);

  StoreAnnouncement get storeAnnouncement => _announcement;

  String announcement(bool hebrew) => _announcement.text(hebrew);

  String get announcementImagePath => _announcement.imagePath;

  int get announcementRevision => _announcement.revision;

  bool get hasAnnouncement => _announcement.hasContent;

  /// Built-in sample deals only for the public demo store (same rule as [CatalogStore]).
  bool get _showBuiltinDeals => DemoStore.isDemoSlug(_linkedBusinessSlug);

  List<Map<String, dynamic>> get allDeals => [
        ..._customDeals.where((d) => !CatalogData.isDealExpired(d)),
        if (_showBuiltinDeals)
          ...CatalogData.deals.where(
            (d) => !CatalogData.isDealExpired(d) && !_hiddenBuiltinDealIds.contains(d['id']),
          ),
      ];

  Map<String, dynamic>? findDealById(String id) {
    for (final deal in allDeals) {
      if (deal['id'] == id) return deal;
    }
    if (id.startsWith('custom_')) {
      for (final deal in _customDeals) {
        if (deal['id'] == id) return deal;
      }
    }
    if (_showBuiltinDeals) {
      for (final deal in CatalogData.deals) {
        if (deal['id'] == id) return deal;
      }
    }
    return null;
  }

  bool isCustomDeal(String id) => id.startsWith('custom_');

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
    _inquiriesLastSeenAtMs = prefs.getInt(_inquiriesLastSeenKey) ?? 0;

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

    _hiddenBuiltinDealIds.clear();
    final rawHidden = prefs.getStringList(_hiddenBuiltinDealsKey);
    if (rawHidden != null) {
      _hiddenBuiltinDealIds.addAll(rawHidden.map((e) => e.trim()).where((e) => e.isNotEmpty));
    }

    _linkedBusinessSlug = prefs.getString(_linkedSlugKey);
    _linkedBusinessId = prefs.getString(_linkedIdKey);
    _customerPanelMode = prefs.getString(_customerPanelModeKey) ?? 'products';
    _storeAppImagePath = prefs.getString(_storeAppImagePathKey) ?? '';
    _storeAppLogoUrl = prefs.getString(_storeAppLogoUrlKey);
    final savedContactEmail = prefs.getString(_storeContactEmailKey);
    _storeContactEmail = savedContactEmail?.trim().isNotEmpty == true ? savedContactEmail!.trim() : null;
    if (_customerPanelMode != 'products' && _customerPanelMode != 'appointments') {
      _customerPanelMode = 'products';
    }
    final storeModeChosen = prefs.getBool(_storeModeChosenKey) ?? false;
    if (_customerPanelMode == 'appointments' && !storeModeChosen) {
      _customerPanelMode = 'products';
      await prefs.setString(_customerPanelModeKey, 'products');
    }

    notifyListenersDeferred();
  }

  /// Links the configured demo store from Supabase (slug `shilo`) for in-app preview.
  Future<bool> ensureDemoStoreLinked({bool preferAppointments = false}) async {
    if (!SupabaseBootstrap.isReady) return false;
    // Keep real linked stores — demo fallback only when nothing is linked yet.
    if (hasLinkedBusiness && !DemoStore.isDemoSlug(_linkedBusinessSlug)) {
      return false;
    }
    try {
      var business = await SaasRepository.instance.fetchDemoBusiness();
      if (business == null) {
        if (!hasLinkedBusiness || DemoStore.isDemoSlug(_linkedBusinessSlug)) {
          return setShareSlug(DemoStore.slug);
        }
        return false;
      }

      if (preferAppointments && business.storeMode != 'appointments') {
        final synced = await _trySyncStoreModeOnServer(business.id, 'appointments');
        if (synced) {
          business = await SaasRepository.instance.fetchDemoBusiness() ?? business;
        }
      }

      if (preferAppointments && _customerPanelMode != 'appointments') {
        await setCustomerPanelMode('appointments');
      }

      if (!hasLinkedBusiness || _linkedBusinessSlug != business.slug) {
        await linkOnlineBusiness(
          id: business.id,
          slug: business.slug,
          contactEmail: business.contactEmail,
        );
        await applyServerBranding(logoUrl: business.logoUrl);
      }
      return true;
    } catch (_) {
      if (!hasLinkedBusiness || DemoStore.isDemoSlug(_linkedBusinessSlug)) {
        return setShareSlug(DemoStore.slug);
      }
      return false;
    }
  }

  /// Keeps demo store [DemoStore.slug] linked so built-in catalog/deals stay visible.
  Future<void> ensureDemoCatalogReady() async {
    final slug = _linkedBusinessSlug?.trim().toLowerCase();
    if (slug != null && slug.isNotEmpty && !DemoStore.isDemoSlug(slug)) {
      return;
    }
    if (!DemoStore.isDemoSlug(slug)) {
      await setShareSlug(DemoStore.slug);
    } else if (slug != DemoStore.slug) {
      _linkedBusinessSlug = DemoStore.slug;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_linkedSlugKey, DemoStore.slug);
      notifyListenersDeferred();
    }
    if (SupabaseBootstrap.isReady) {
      unawaited(ensureDemoStoreLinked());
    }
  }

  Future<bool> _trySyncStoreModeOnServer(String businessId, String mode) async {
    if (!SupabaseBootstrap.isReady || SaasRepository.instance.currentUser == null) {
      return false;
    }
    try {
      await SaasRepository.instance.setBusinessStoreMode(
        businessId: businessId,
        storeMode: mode,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// When UI is in appointment mode, align linked business + server (if owner signed in).
  Future<void> ensureAppointmentModeReady() async {
    if (!isAppointmentCustomerMode) return;
    if (!hasLinkedBusiness) {
      await ensureDemoStoreLinked(preferAppointments: true);
      return;
    }
    if (_linkedBusinessSlug == null) return;
    try {
      var fresh = await SaasRepository.instance.fetchBusinessBySlug(_linkedBusinessSlug!);
      if (fresh == null) {
        await ensureDemoStoreLinked(preferAppointments: true);
        return;
      }
      if (fresh.storeMode != 'appointments') {
        await _trySyncStoreModeOnServer(fresh.id, 'appointments');
        fresh = await SaasRepository.instance.fetchBusinessBySlug(fresh.slug) ?? fresh;
      }
      if (fresh.storeMode != 'appointments' && !DemoStore.isDemoSlug(fresh.slug)) {
        await ensureDemoStoreLinked(preferAppointments: true);
        return;
      }
      if (_customerPanelMode != 'appointments') {
        await setCustomerPanelMode('appointments');
      }
      if (_linkedBusinessId != fresh.id || _linkedBusinessSlug != fresh.slug) {
        await linkOnlineBusiness(
          id: fresh.id,
          slug: fresh.slug,
          contactEmail: fresh.contactEmail,
        );
      }
    } catch (_) {
      await ensureDemoStoreLinked(preferAppointments: true);
    }
  }

  Future<void> setCustomerPanelMode(String mode) async {
    if (mode != 'products' && mode != 'appointments') return;
    if (_customerPanelMode == mode) return;
    _customerPanelMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customerPanelModeKey, mode);
    await prefs.setBool(_storeModeChosenKey, true);
    notifyListenersDeferred();
  }

  /// Saves a slug for sharing when Supabase is unavailable (local / manual setup).
  Future<bool> setShareSlug(String rawSlug) async {
    var s = rawSlug.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    s = s.replaceAll(RegExp(r'\s+'), '-');
    s = s.replaceAll(RegExp(r'-+'), '-');
    s = s.replaceAll(RegExp(r'^-|-$'), '');
    if (s.isEmpty) return false;
    final demo = DemoStore.isDemoSlug(s);
    if (demo) s = DemoStore.slug;
    _linkedBusinessSlug = s;
    _linkedBusinessId = demo ? 'local' : (_linkedBusinessId ?? 'local');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_linkedSlugKey, s);
    await prefs.setString(_linkedIdKey, _linkedBusinessId!);
    if (demo) {
      _storeContactEmail = DemoStore.defaultContactEmail;
      await prefs.setString(_storeContactEmailKey, DemoStore.defaultContactEmail);
    }
    unawaited(reloadStoreScopedData());
    notifyListenersDeferred();
    return true;
  }

  Future<void> linkOnlineBusiness({
    required String id,
    required String slug,
    String? storeMode,
    String? contactEmail,
  }) async {
    final previousSlug = _linkedBusinessSlug?.trim().toLowerCase();
    final newSlug = DemoStore.isDemoSlug(slug)
        ? DemoStore.slug
        : slug.trim().toLowerCase();
    var newContact = contactEmail?.trim();
    if ((newContact == null || newContact.isEmpty) && DemoStore.isDemoSlug(newSlug)) {
      newContact = DemoStore.defaultContactEmail;
    }
    final slugChanged = previousSlug != newSlug;
    final changed = _linkedBusinessId != id ||
        _linkedBusinessSlug != newSlug ||
        _storeContactEmail != newContact;
    _linkedBusinessId = id;
    _linkedBusinessSlug = newSlug;
    if (newContact != null && newContact.isNotEmpty) {
      _storeContactEmail = newContact;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_linkedSlugKey, _linkedBusinessSlug!);
    await prefs.setString(_linkedIdKey, id);
    if (newContact != null) {
      await prefs.setString(_storeContactEmailKey, newContact);
    }
    final normalizedMode = storeMode?.trim();
    var modeChanged = false;
    if (normalizedMode == 'appointments') {
      if (_customerPanelMode != 'appointments') {
        _customerPanelMode = 'appointments';
        await prefs.setString(_customerPanelModeKey, 'appointments');
        await prefs.setBool(_storeModeChosenKey, true);
        modeChanged = true;
      }
    } else if (normalizedMode == 'products') {
      if (_customerPanelMode != 'products') {
        _customerPanelMode = 'products';
        await prefs.setString(_customerPanelModeKey, 'products');
        await prefs.setBool(_storeModeChosenKey, true);
        modeChanged = true;
      }
    } else if (slugChanged && !DemoStore.isDemoSlug(newSlug) && _customerPanelMode != 'products') {
      _customerPanelMode = 'products';
      await prefs.setString(_customerPanelModeKey, 'products');
      modeChanged = true;
    }
    if (slugChanged) unawaited(reloadStoreScopedData());
    if (changed || modeChanged) notifyListenersDeferred();
  }

  Future<bool> setStoreContactEmail(String? rawEmail) async {
    final trimmed = rawEmail?.trim() ?? '';
    if (trimmed.isNotEmpty && !isValidEmailAddress(trimmed)) return false;
    final email = trimmed.isEmpty ? null : trimmed;
    if (_storeContactEmail == email) return true;
    _storeContactEmail = email;
    final prefs = await SharedPreferences.getInstance();
    if (email != null) {
      await prefs.setString(_storeContactEmailKey, email);
    } else {
      await prefs.remove(_storeContactEmailKey);
    }
    final businessId = _linkedBusinessId;
    if (SupabaseBootstrap.isReady &&
        businessId != null &&
        businessId.isNotEmpty &&
        businessId != 'local') {
      try {
        await SaasRepository.instance.updateBusinessContactEmail(
          businessId: businessId,
          contactEmail: email,
        );
      } catch (_) {
        return false;
      }
    }
    notifyListenersDeferred();
    return true;
  }

  Future<void> refreshStoreContactEmail() async {
    final slug = _linkedBusinessSlug;
    if (!SupabaseBootstrap.isReady || slug == null || slug.isEmpty) return;
    try {
      final business = await SaasRepository.instance.fetchBusinessBySlug(slug);
      if (business == null) return;
      final email = business.contactEmail?.trim();
      if (email == null || email.isEmpty) return;
      _storeContactEmail = email;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storeContactEmailKey, email);
      notifyListenersDeferred();
    } catch (_) {}
  }

  Future<void> applyServerBranding({String? logoUrl}) async {
    final url = logoUrl?.trim();
    if (url == null || url.isEmpty) return;
    if (_storeAppLogoUrl == url) return;
    _storeAppLogoUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeAppLogoUrlKey, url);
    notifyListenersDeferred();
  }

  Future<void> setStoreAppImageFromPicker(String sourcePath) async {
    final saved = await CatalogImageStorage.saveBrandFromPicker(sourcePath);
    _storeAppImagePath = saved;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeAppImagePathKey, saved);

    final businessId = _linkedBusinessId;
    if (SupabaseBootstrap.isReady &&
        businessId != null &&
        businessId != 'local' &&
        SaasRepository.instance.currentUser != null) {
      try {
        final url = await SaasRepository.instance.uploadBusinessLogo(
          businessId: businessId,
          localPath: saved,
        );
        await SaasRepository.instance.updateBusinessLogoUrl(
          businessId: businessId,
          logoUrl: url,
        );
        _storeAppLogoUrl = url;
        await prefs.setString(_storeAppLogoUrlKey, url);
      } catch (_) {
        // Local image still applies for manager + customers on this device.
      }
    }
    notifyListeners();
  }

  Future<void> clearStoreAppImage() async {
    _storeAppImagePath = '';
    _storeAppLogoUrl = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storeAppImagePathKey);
    await prefs.remove(_storeAppLogoUrlKey);
    notifyListeners();
  }

  Future<void> refreshStoreBrandingFromServer() async {
    final slug = _linkedBusinessSlug;
    if (!SupabaseBootstrap.isReady || slug == null || slug.isEmpty) return;
    try {
      final business = await SaasRepository.instance.fetchBusinessBySlug(slug);
      if (business?.logoUrl != null && business!.logoUrl!.trim().isNotEmpty) {
        await applyServerBranding(logoUrl: business.logoUrl);
      }
    } catch (_) {}
  }

  Future<void> applyServerStoreMode(String mode) async {
    if (mode != 'products' && mode != 'appointments') return;
    if (_customerPanelMode == mode) return;
    _customerPanelMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customerPanelModeKey, mode);
    await prefs.setBool(_storeModeChosenKey, true);
    notifyListenersDeferred();
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
    String? customerPhone,
    String? reason,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;
    _inquiries.insert(
      0,
      CustomerInquiry(
        id: 'inq_${DateTime.now().millisecondsSinceEpoch}',
        customerName: customerName,
        customerPhone: customerPhone?.trim().isNotEmpty == true ? customerPhone!.trim() : null,
        reason: reason?.trim().isNotEmpty == true ? reason!.trim() : null,
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

  List<CustomerInquiry> inquiriesForCustomer({String? phone, String? name}) {
    final normalizedPhone = phone?.trim();
    final normalizedName = name?.trim().toLowerCase();
    return _inquiries.where((inq) {
      if (normalizedPhone != null &&
          normalizedPhone.isNotEmpty &&
          inq.customerPhone?.trim() == normalizedPhone) {
        return true;
      }
      if (normalizedName != null &&
          normalizedName.isNotEmpty &&
          inq.customerName?.trim().toLowerCase() == normalizedName) {
        return true;
      }
      return false;
    }).toList();
  }

  bool hasUnreadInquiryRepliesForCustomer({String? phone, String? name}) {
    return inquiriesForCustomer(phone: phone, name: name)
        .any((inq) => inq.hasReply && !inq.replySeenByCustomer);
  }

  Future<void> replyToInquiry({required String id, required String reply}) async {
    final trimmed = reply.trim();
    if (trimmed.isEmpty) return;
    final index = _inquiries.indexWhere((inq) => inq.id == id);
    if (index < 0) return;
    _inquiries[index] = _inquiries[index].copyWith(
      replyText: trimmed,
      replyAtMs: DateTime.now().millisecondsSinceEpoch,
      replySeenByCustomer: false,
    );
    await _persistInquiries();
    notifyListeners();
  }

  Future<void> markInquiryRepliesSeenForCustomer({String? phone, String? name}) async {
    var changed = false;
    for (var i = 0; i < _inquiries.length; i++) {
      final inq = _inquiries[i];
      if (!inq.hasReply || inq.replySeenByCustomer) continue;
      final matchesPhone = phone?.trim().isNotEmpty == true && inq.customerPhone?.trim() == phone!.trim();
      final matchesName = name?.trim().isNotEmpty == true &&
          inq.customerName?.trim().toLowerCase() == name!.trim().toLowerCase();
      if (matchesPhone || matchesName) {
        _inquiries[i] = inq.copyWith(replySeenByCustomer: true);
        changed = true;
      }
    }
    if (!changed) return;
    await _persistInquiries();
    notifyListeners();
  }

  Future<void> markInquiriesSeen() async {
    if (_inquiries.isEmpty) return;
    final newest = _inquiries.first.createdAtMs;
    if (newest <= _inquiriesLastSeenAtMs) return;
    _inquiriesLastSeenAtMs = newest;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_inquiriesLastSeenKey, _inquiriesLastSeenAtMs);
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
  Future<void> setAnnouncementFromText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      await setAnnouncement(he: '', en: '', imagePath: '', notifyCustomers: true);
      return;
    }
    final bilingual = await LocaleTranslate.toBilingual(trimmed);
    await setAnnouncement(he: bilingual.he, en: bilingual.en, imagePath: '', notifyCustomers: true);
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
      unawaited(
        DealPushService.notifyCustomersOfDeal(
          titleHe: titleHe,
          titleEn: titleEn,
          bodyHe: descHe,
          bodyEn: descEn,
        ),
      );
    }
    notifyListeners();
  }

  Future<void> removeDeal(String id) async {
    if (isCustomDeal(id)) {
      _customDeals.removeWhere((d) => d['id'] == id);
      await _persistDeals();
    } else {
      _hiddenBuiltinDealIds.add(id);
      await _persistHiddenBuiltinDeals();
    }
    notifyListeners();
  }

  Future<void> updateDeal({
    required String id,
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
  final dealMap = {
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
    };

    if (isCustomDeal(id)) {
      final idx = _customDeals.indexWhere((d) => d['id'] == id);
      if (idx < 0) return;
      _customDeals[idx] = {'id': id, ...dealMap};
      await _persistDeals();
      if (notifyCustomers) {
        await queueDealAlert(titleHe: titleHe, titleEn: titleEn);
        unawaited(
          DealPushService.notifyCustomersOfDeal(
            titleHe: titleHe,
            titleEn: titleEn,
            bodyHe: descHe,
            bodyEn: descEn,
          ),
        );
      }
      notifyListeners();
      return;
    }

    _hiddenBuiltinDealIds.add(id);
    await _persistHiddenBuiltinDeals();
    final newId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    _customDeals.insert(0, {'id': newId, ...dealMap});
    await _persistDeals();
    if (notifyCustomers) {
      await queueDealAlert(titleHe: titleHe, titleEn: titleEn);
      unawaited(
        DealPushService.notifyCustomersOfDeal(
          titleHe: titleHe,
          titleEn: titleEn,
          bodyHe: descHe,
          bodyEn: descEn,
        ),
      );
    }
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

  Future<void> _persistHiddenBuiltinDeals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_hiddenBuiltinDealsKey, _hiddenBuiltinDealIds.toList()..sort());
  }
}
