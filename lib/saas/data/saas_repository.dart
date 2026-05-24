import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/demo_store.dart';
import '../../core/supabase/supabase_bootstrap.dart';
import '../../core/legal_versions.dart';
import '../models/appointment_models.dart';
import '../models/business_payment_settings.dart';
import '../models/legal_acceptance.dart';
import '../models/saas_models.dart';
import '../utils/slug_utils.dart';

class _CachedBusiness {
  const _CachedBusiness(this.business, this.cachedAt);
  final SaasBusiness business;
  final DateTime cachedAt;
}

class SaasRepository {
  SaasRepository._();
  static final SaasRepository instance = SaasRepository._();

  static const _businessCacheTtl = Duration(minutes: 5);
  static const _profileCacheTtl = Duration(minutes: 2);

  final Map<String, _CachedBusiness> _businessBySlug = {};
  SaasProfile? _cachedProfile;
  String? _cachedProfileUserId;
  DateTime? _cachedProfileAt;

  SupabaseClient get _db => SupabaseBootstrap.client;

  void invalidateBusinessCache({String? slug}) {
    if (slug == null) {
      _businessBySlug.clear();
      return;
    }
    _businessBySlug.remove(normalizeSlug(slug));
  }

  void invalidateProfileCache() {
    _cachedProfile = null;
    _cachedProfileUserId = null;
    _cachedProfileAt = null;
  }

  void _cacheBusiness(SaasBusiness business) {
    _businessBySlug[normalizeSlug(business.slug)] = _CachedBusiness(business, DateTime.now());
  }

  User? get currentUser => _db.auth.currentUser;

  Stream<AuthState> get authStateChanges => _db.auth.onAuthStateChange;

  Future<void> signInWithEmail({required String email, required String password}) async {
    await _db.auth.signInWithPassword(email: email, password: password);
  }

  /// Returns true when the user has an active session (signed in).
  /// Returns false when sign-up succeeded but email confirmation is still required.
  Future<bool> signUpWithEmail({required String email, required String password}) async {
    final res = await _db.auth.signUp(email: email, password: password);
    if (res.session != null) return true;
    return false;
  }

  Future<void> resendSignupConfirmation(String email) async {
    await _db.auth.resend(type: OtpType.signup, email: email.trim());
  }

  Future<void> resetPasswordForEmail(String email) async {
    await _db.auth.resetPasswordForEmail(email.trim());
  }

  Future<bool> verifyBusinessManagerPin({required String slug, required String pin}) async {
    final result = await _db.rpc(
      'verify_business_manager_pin',
      params: {'p_slug': normalizeSlug(slug), 'p_pin': pin.trim()},
    );
    return result == true;
  }

  Future<void> updateMyBusinessManagerPin(String pin) async {
    await _db.rpc('update_my_business_manager_pin', params: {'p_pin': pin.trim()});
  }

  /// Owner signs in, verifies store ownership, updates manager panel PIN, then signs out.
  Future<void> changeManagerPinForOwnedStore({
    required String slug,
    required String ownerEmail,
    required String ownerPassword,
    required String newPin,
  }) async {
    final normalized = normalizeSlug(slug);
    if (normalized.isEmpty) {
      throw Exception('Invalid store name');
    }
    await signInWithEmail(email: ownerEmail.trim(), password: ownerPassword);
    try {
      final businesses = await fetchOwnedBusinesses();
      final ownsStore = businesses.any((b) => b.slug == normalized);
      if (!ownsStore) {
        throw Exception('Store not found or you are not the owner');
      }
      await updateMyBusinessManagerPin(newPin);
    } finally {
      await signOut();
    }
  }

  Future<void> signOut() async {
    invalidateProfileCache();
    await _db.auth.signOut();
  }

  /// Throws if the signed-in user is not [SaasProfile.isSuperAdmin] (enforced via RLS read).
  Future<SaasProfile> requireSuperAdmin() async {
    final profile = await fetchCurrentProfile();
    if (profile == null || !profile.isSuperAdmin) {
      throw Exception('Forbidden');
    }
    return profile;
  }

  Future<SaasProfile?> fetchCurrentProfile({
    bool createIfMissing = true,
    bool forceRefresh = false,
  }) async {
    final uid = currentUser?.id;
    if (uid == null) return null;

    if (!forceRefresh &&
        _cachedProfile != null &&
        _cachedProfileUserId == uid &&
        _cachedProfileAt != null &&
        DateTime.now().difference(_cachedProfileAt!) < _profileCacheTtl) {
      return _cachedProfile;
    }

    if (createIfMissing) {
      try {
        final ensured = await _db.rpc('ensure_my_profile');
        if (ensured != null) {
          final profile = SaasProfile.fromJson(Map<String, dynamic>.from(ensured as Map));
          _cachedProfile = profile;
          _cachedProfileUserId = uid;
          _cachedProfileAt = DateTime.now();
          return profile;
        }
      } catch (_) {
        // Fall through to select/upsert below.
      }
    }

    var row = await _db.from('profiles').select().eq('id', uid).maybeSingle();
    if (row == null && createIfMissing) {
      final user = currentUser!;
      await _db.from('profiles').upsert({
        'id': uid,
        'email': user.email ?? '',
        'full_name': (user.userMetadata?['full_name'] as String?) ?? '',
      });
      row = await _db.from('profiles').select().eq('id', uid).maybeSingle();
    }
    if (row == null) return null;
    final profile = SaasProfile.fromJson(Map<String, dynamic>.from(row));
    _cachedProfile = profile;
    _cachedProfileUserId = uid;
    _cachedProfileAt = DateTime.now();
    return profile;
  }

  Future<bool> isSlugAvailable(String slug) async {
    final normalized = normalizeSlug(slug);
    final result = await _db.rpc('is_slug_available', params: {'p_slug': normalized});
    return result == true;
  }

  /// Picks a unique public slug from [businessName] (adds suffix if taken).
  Future<String> allocateSlugForBusinessName(String businessName) async {
    var base = normalizeSlug(businessName);
    if (base.isEmpty) {
      final uid = currentUser?.id;
      base = uid != null && uid.length >= 8
          ? 'store-${uid.substring(0, 8)}'
          : 'store-${DateTime.now().millisecondsSinceEpoch}';
    }
    if (slugIsReserved(base)) base = '${base}-shop';

    var candidate = base;
    for (var n = 0; n < 100; n++) {
      if (!slugIsReserved(candidate) && await isSlugAvailable(candidate)) {
        return candidate;
      }
      candidate = n == 0 ? '$base-2' : '$base-${n + 2}';
    }
    throw Exception('Could not allocate a store link. Please try again.');
  }

  Future<SaasBusiness?> fetchBusinessBySlug(String slug, {bool forceRefresh = false}) async {
    final normalized = normalizeSlug(slug);
    if (normalized.isEmpty) return null;

    if (!forceRefresh) {
      final cached = _businessBySlug[normalized];
      if (cached != null &&
          DateTime.now().difference(cached.cachedAt) < _businessCacheTtl) {
        return cached.business;
      }
    }

    final row = await _db.from('businesses').select().eq('slug', normalized).maybeSingle();
    if (row == null) {
      _businessBySlug.remove(normalized);
      return null;
    }
    final business = SaasBusiness.fromJson(Map<String, dynamic>.from(row));
    _cacheBusiness(business);
    return business;
  }

  /// Demo store on server — tries canonical slug then legacy alias.
  Future<SaasBusiness?> fetchDemoBusiness() async {
    for (final candidate in DemoStore.serverSlugs) {
      final business = await fetchBusinessBySlug(candidate);
      if (business != null) return business;
    }
    return null;
  }

  Future<String> uploadBusinessLogo({
    required String businessId,
    required String localPath,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) throw Exception('Image file not found');
    var ext = p.extension(localPath).toLowerCase();
    if (ext.isEmpty) ext = '.jpg';
    if (ext == '.jpeg') ext = '.jpg';
    final contentType = switch (ext) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    final objectPath = '$businessId/logo${DateTime.now().millisecondsSinceEpoch}$ext';
    await _db.storage.from('business-logos').upload(
          objectPath,
          file,
          fileOptions: FileOptions(upsert: true, contentType: contentType),
        );
    return _db.storage.from('business-logos').getPublicUrl(objectPath);
  }

  Future<void> updateBusinessLogoUrl({
    required String businessId,
    required String logoUrl,
  }) async {
    await _db.from('businesses').update({'logo_url': logoUrl}).eq('id', businessId);
    invalidateBusinessCache();
  }

  Future<void> updateBusinessStoreTerms({
    required String businessId,
    String? storeTerms,
  }) async {
    await _db.from('businesses').update({'store_terms': storeTerms}).eq('id', businessId);
    invalidateBusinessCache();
  }

  Future<void> updateBusinessContactEmail({
    required String businessId,
    String? contactEmail,
  }) async {
    await _db
        .from('businesses')
        .update({'contact_email': contactEmail})
        .eq('id', businessId);
    invalidateBusinessCache();
  }

  Future<SaasBusiness?> fetchOwnedBusiness() async {
    final list = await fetchOwnedBusinesses();
    return list.isEmpty ? null : list.first;
  }

  Future<List<SaasBusiness>> fetchOwnedBusinesses() async {
    final uid = currentUser?.id;
    if (uid == null) return [];
    final rows = await _db
        .from('businesses')
        .select()
        .eq('owner_id', uid)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => SaasBusiness.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<SaasProduct>> fetchActiveProducts(String businessId) async {
    final rows = await _db
        .from('products')
        .select()
        .eq('business_id', businessId)
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => SaasProduct.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> createBusinessViaEdge({
    required String businessName,
    required String slug,
    required String managerPin,
    String? description,
    String? logoUrl,
    String? phone,
    String? businessType,
    String? address,
    String? contactEmail,
  }) async {
    final res = await _db.functions.invoke(
      'create-business',
      body: {
        'business_name': businessName,
        'slug': slug,
        'manager_pin': managerPin,
        if (description != null) 'description': description,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (phone != null) 'phone': phone,
        if (businessType != null) 'business_type': businessType,
        if (address != null) 'address': address,
        if (contactEmail != null) 'contact_email': contactEmail,
      },
    );
    if (res.status >= 400) {
      final err = res.data is Map ? (res.data as Map)['error']?.toString() : res.data?.toString();
      throw Exception(err ?? 'Failed to create store');
    }
    final data = Map<String, dynamic>.from(res.data as Map);
    final businessJson = data['business'];
    if (businessJson is Map) {
      _cacheBusiness(SaasBusiness.fromJson(Map<String, dynamic>.from(businessJson)));
    }
    return data;
  }

  /// Returns a dev OTP code when the server responds with [dev_code] (development only).
  Future<String?> sendPhoneOtp(String phone) async {
    final res = await _db.functions.invoke('send-phone-otp', body: {'phone': phone});
    if (res.status >= 400) {
      final err = res.data is Map ? (res.data as Map)['error']?.toString() : null;
      throw Exception(err ?? 'Failed to send code');
    }
    if (res.data is Map) {
      final code = (res.data as Map)['dev_code']?.toString();
      if (code != null && code.isNotEmpty) return code;
    }
    return null;
  }

  Future<void> verifyPhoneOtp({required String phone, required String code}) async {
    final res = await _db.functions.invoke(
      'verify-phone-otp',
      body: {'phone': phone, 'code': code},
    );
    if (res.status >= 400) {
      final err = res.data is Map ? (res.data as Map)['error']?.toString() : null;
      throw Exception(err ?? 'Invalid code');
    }
    invalidateProfileCache();
  }

  Future<List<SaasBusinessAdminRow>> fetchAllBusinessesForSuperAdmin() async {
    await requireSuperAdmin();
    final rows = await _db
        .from('businesses')
        .select('*, profiles!businesses_owner_id_fkey(email)')
        .order('created_at', ascending: false);
    final list = <SaasBusinessAdminRow>[];
    for (final raw in rows as List) {
      final map = Map<String, dynamic>.from(raw as Map);
      final owner = map['profiles'] as Map<String, dynamic>?;
      final business = SaasBusiness.fromJson(map);
      final products = await _db.from('products').select('id').eq('business_id', business.id);
      final orders = await _db.from('orders').select('id').eq('business_id', business.id);
      final appointments =
          await _db.from('appointments').select('id').eq('business_id', business.id);
      final orderCustomers = await _db
          .from('orders')
          .select('customer_phone, customer_email, customer_user_id, customer_name')
          .eq('business_id', business.id);
      final appointmentCustomers = await _db
          .from('appointments')
          .select('customer_phone, customer_email, customer_name')
          .eq('business_id', business.id);
      list.add(
        SaasBusinessAdminRow(
          business: business,
          ownerEmail: owner?['email'] as String?,
          productCount: (products as List).length,
          orderCount: (orders as List).length,
          appointmentCount: (appointments as List).length,
          customerCount: _countUniqueCustomers(
            (orderCustomers as List).cast<Map<String, dynamic>>(),
            (appointmentCustomers as List).cast<Map<String, dynamic>>(),
          ),
        ),
      );
    }
    return list;
  }

  Future<void> superAdminUpdateBusiness({
    required String businessId,
    bool? isActive,
    String? subscriptionStatus,
    String? storeMode,
  }) async {
    await requireSuperAdmin();
    final res = await _db.functions.invoke(
      'super-admin-business',
      body: {
        'business_id': businessId,
        if (isActive != null) 'is_active': isActive,
        if (subscriptionStatus != null) 'subscription_status': subscriptionStatus,
        if (storeMode != null) 'store_mode': storeMode,
      },
    );
    if (res.status >= 400) {
      final err = res.data is Map ? (res.data as Map)['error']?.toString() : null;
      throw Exception(err ?? 'Update failed');
    }
  }

  Future<List<SaasBusinessAdminRow>> fetchAllBusinessesForCreator(String password) async {
    try {
      final profile = await fetchCurrentProfile(createIfMissing: false);
      if (profile?.isSuperAdmin == true) {
        return fetchAllBusinessesForSuperAdmin();
      }
    } catch (_) {}

    final res = await _db.functions.invoke(
      'creator-admin',
      body: {'password': password, 'action': 'list'},
    );
    if (res.status >= 400) {
      final err = res.data is Map ? (res.data as Map)['error']?.toString() : null;
      throw Exception(err ?? 'Forbidden');
    }
    return _parseCreatorAdminRows(res.data);
  }

  Future<void> creatorUpdateBusiness({
    required String password,
    required String businessId,
    bool? isActive,
    String? subscriptionStatus,
    String? storeMode,
  }) async {
    try {
      final profile = await fetchCurrentProfile(createIfMissing: false);
      if (profile?.isSuperAdmin == true) {
        await superAdminUpdateBusiness(
          businessId: businessId,
          isActive: isActive,
          subscriptionStatus: subscriptionStatus,
          storeMode: storeMode,
        );
        return;
      }
    } catch (_) {}

    final res = await _db.functions.invoke(
      'creator-admin',
      body: {
        'password': password,
        'action': 'update',
        'business_id': businessId,
        if (isActive != null) 'is_active': isActive,
        if (subscriptionStatus != null) 'subscription_status': subscriptionStatus,
        if (storeMode != null) 'store_mode': storeMode,
      },
    );
    if (res.status >= 400) {
      final err = res.data is Map ? (res.data as Map)['error']?.toString() : null;
      throw Exception(err ?? 'Update failed');
    }
  }

  List<SaasBusinessAdminRow> _parseCreatorAdminRows(dynamic data) {
    if (data is! Map) return [];
    final businesses = data['businesses'] as List? ?? [];
    return businesses.map((raw) {
      final map = Map<String, dynamic>.from(raw as Map);
      final businessMap = Map<String, dynamic>.from(map['business'] as Map);
      businessMap.remove('profiles');
      return SaasBusinessAdminRow(
        business: SaasBusiness.fromJson(businessMap),
        ownerEmail: map['owner_email'] as String?,
        productCount: (map['product_count'] as num?)?.toInt() ?? 0,
        orderCount: (map['order_count'] as num?)?.toInt() ?? 0,
        appointmentCount: (map['appointment_count'] as num?)?.toInt() ?? 0,
        customerCount: (map['customer_count'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<void> createOrder({
    required String businessId,
    required String customerName,
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    String? customerPhone,
    String? customerEmail,
  }) async {
    await _db.from('orders').insert({
      'business_id': businessId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'customer_user_id': currentUser?.id,
      'items': items,
      'total_price': totalPrice,
      'status': 'new',
    });
  }

  Future<PublicAppointmentSchedule> fetchPublicAppointmentSchedule({
    required String slug,
    required DateTime from,
    required DateTime to,
  }) async {
    final result = await _db.rpc(
      'get_public_appointment_schedule',
      params: {
        'p_slug': slug,
        'p_from_date': _dateOnly(from),
        'p_to_date': _dateOnly(to),
      },
    );
    return PublicAppointmentSchedule.fromJson(Map<String, dynamic>.from(result as Map));
  }

  Future<String> bookAppointmentViaRpc({
    required String businessId,
    required DateTime date,
    required String timeHHmm,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    String? notes,
  }) async {
    final result = await _db.rpc(
      'book_appointment',
      params: {
        'p_business_id': businessId,
        'p_appointment_date': _dateOnly(date),
        'p_appointment_time': '$timeHHmm:00',
        'p_customer_name': customerName,
        'p_customer_phone': customerPhone,
        'p_customer_email': customerEmail,
        'p_notes': notes,
      },
    );
    final map = Map<String, dynamic>.from(result as Map);
    if (map['ok'] != true) {
      throw Exception(map['error']?.toString() ?? 'Booking failed');
    }
    return map['appointment_id'] as String;
  }

  Future<void> joinAppointmentWaitlist({
    required String businessId,
    required DateTime date,
    required String timeHHmm,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
  }) async {
    final result = await _db.rpc(
      'join_appointment_waitlist',
      params: {
        'p_business_id': businessId,
        'p_appointment_date': _dateOnly(date),
        'p_appointment_time': '$timeHHmm:00',
        'p_customer_name': customerName,
        'p_customer_phone': customerPhone,
        'p_customer_email': customerEmail,
      },
    );
    final map = Map<String, dynamic>.from(result as Map);
    if (map['ok'] != true) {
      throw Exception(map['error']?.toString() ?? 'Could not join waitlist');
    }
  }

  Future<void> setBusinessStoreMode({
    required String businessId,
    required String storeMode,
  }) async {
    final result = await _db.rpc(
      'set_business_store_mode',
      params: {'p_business_id': businessId, 'p_store_mode': storeMode},
    );
    final map = Map<String, dynamic>.from(result as Map);
    if (map['ok'] != true) {
      throw Exception(map['error']?.toString() ?? 'Could not update store mode');
    }
  }

  Future<List<SaasAppointment>> fetchBusinessAppointments({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await _db
        .from('appointments')
        .select()
        .eq('business_id', businessId)
        .gte('appointment_date', _dateOnly(from))
        .lte('appointment_date', _dateOnly(to))
        .order('appointment_date')
        .order('appointment_time');
    return (rows as List)
        .map((e) => SaasAppointment.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<SaasAppointment>> fetchCustomerAppointments({
    required String businessId,
    required String customerPhone,
  }) async {
    final result = await _db.rpc(
      'get_customer_appointments',
      params: {
        'p_business_id': businessId,
        'p_customer_phone': customerPhone.trim(),
      },
    );
    final map = Map<String, dynamic>.from(result as Map);
    if (map['ok'] != true) {
      throw Exception(map['error']?.toString() ?? 'Could not load appointments');
    }
    final raw = map['appointments'] as List<dynamic>? ?? [];
    return raw
        .map((e) => SaasAppointment.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> cancelAppointment(
    String appointmentId, {
    String? customerPhone,
  }) async {
    final result = await _db.rpc(
      'cancel_appointment',
      params: {
        'p_appointment_id': appointmentId,
        if (customerPhone != null && customerPhone.trim().isNotEmpty)
          'p_customer_phone': customerPhone.trim(),
      },
    );
    final map = Map<String, dynamic>.from(result as Map);
    if (map['ok'] != true) {
      throw Exception(map['error']?.toString() ?? 'Cancel failed');
    }
  }

  Future<void> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    final result = await _db.rpc(
      'update_appointment_status',
      params: {'p_appointment_id': appointmentId, 'p_status': status},
    );
    final map = Map<String, dynamic>.from(result as Map);
    if (map['ok'] != true) {
      throw Exception(map['error']?.toString() ?? 'Update failed');
    }
  }

  Future<List<AppointmentWaitlistEntry>> fetchWaitlist(String businessId) async {
    final rows = await _db
        .from('appointment_waitlist')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false)
        .limit(50);
    return (rows as List)
        .map((e) => AppointmentWaitlistEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<BusinessAppointmentSettings?> fetchAppointmentSettings(String businessId) async {
    final row = await _db
        .from('business_appointment_settings')
        .select()
        .eq('business_id', businessId)
        .maybeSingle();
    if (row == null) return null;
    return BusinessAppointmentSettings.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> updateAppointmentSettings({
    required String businessId,
    int? slotDurationMinutes,
    int? bookingNoticeMinutes,
    int? maxDaysAhead,
  }) async {
    final patch = <String, dynamic>{'business_id': businessId};
    if (slotDurationMinutes != null) patch['slot_duration_minutes'] = slotDurationMinutes;
    if (bookingNoticeMinutes != null) patch['booking_notice_minutes'] = bookingNoticeMinutes;
    if (maxDaysAhead != null) patch['max_days_ahead'] = maxDaysAhead;
    if (patch.length <= 1) return;
    await _db.from('business_appointment_settings').upsert(patch, onConflict: 'business_id');
  }

  Future<List<BusinessAvailabilityRow>> fetchBusinessAvailability(String businessId) async {
    final rows = await _db
        .from('business_availability')
        .select()
        .eq('business_id', businessId)
        .order('day_of_week');
    return (rows as List)
        .map((e) => BusinessAvailabilityRow.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> replaceBusinessAvailability({
    required String businessId,
    required List<BusinessAvailabilityRow> rows,
  }) async {
    await _db.from('business_availability').delete().eq('business_id', businessId);
    if (rows.isEmpty) return;
    await _db.from('business_availability').insert(
      rows.map((r) => r.toInsertJson(businessId)).toList(),
    );
  }

  /// Customer-to-business payment instructions (not Peymiz subscription billing).
  Future<BusinessPaymentSettings?> fetchPaymentSettings(String businessId) async {
    final row = await _db
        .from('business_payment_settings')
        .select()
        .eq('business_id', businessId)
        .maybeSingle();
    if (row == null) return null;
    return BusinessPaymentSettings.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> upsertPaymentSettings(BusinessPaymentSettings settings) async {
    await _db.from('business_payment_settings').upsert(settings.toUpsertJson());
  }

  static String _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().split('T').first;

  Future<LegalAcceptance?> fetchLegalAcceptance() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    final row = await _db.from('legal_acceptances').select().eq('user_id', uid).maybeSingle();
    if (row == null) return null;
    return LegalAcceptance.fromJson(Map<String, dynamic>.from(row));
  }

  Future<bool> hasAcceptedCurrentLegal() async {
    final row = await fetchLegalAcceptance();
    if (row == null) return false;
    return row.coversCurrentVersions(
      termsVersion: LegalVersions.termsVersion,
      privacyVersion: LegalVersions.privacyVersion,
    );
  }

  Future<void> recordLegalAcceptance() async {
    final uid = currentUser?.id;
    if (uid == null) throw Exception('Sign in required');
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.from('legal_acceptances').upsert({
      'user_id': uid,
      'accepted_terms_at': now,
      'accepted_privacy_at': now,
      'terms_version': LegalVersions.termsVersion,
      'privacy_version': LegalVersions.privacyVersion,
      'updated_at': now,
    });
  }

  Future<void> sendCustomerMessage({
    required String businessId,
    required String message,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) async {
    await submitStoreInquiry(
      businessId: businessId,
      message: message,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      channel: 'message',
    );
  }

  Future<void> registerStorePushToken({
    required String businessSlug,
    required String fcmToken,
    String locale = 'he',
  }) async {
    final slug = normalizeSlug(businessSlug);
    await _db.from('store_push_tokens').upsert(
      {
        'business_slug': slug,
        'fcm_token': fcmToken,
        'platform': Platform.isAndroid ? 'android' : 'other',
        'locale': locale,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'business_slug,fcm_token',
    );
  }

  Future<void> notifyDealPush({
    required String businessSlug,
    required String titleHe,
    required String titleEn,
    String? bodyHe,
    String? bodyEn,
  }) async {
    final res = await _db.functions.invoke(
      'notify-deal-push',
      body: {
        'business_slug': normalizeSlug(businessSlug),
        'title_he': titleHe,
        'title_en': titleEn,
        if (bodyHe != null) 'body_he': bodyHe,
        if (bodyEn != null) 'body_en': bodyEn,
      },
    );
    if (res.status >= 400) {
      final err = res.data is Map ? (res.data as Map)['error']?.toString() : res.data?.toString();
      throw Exception(err ?? 'Failed to send deal notification');
    }
  }

  /// Saves inquiry in DB and emails the store contact (when configured on server).
  Future<StoreInquiryResult> submitStoreInquiry({
    String? businessId,
    String? businessSlug,
    required String message,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String channel = 'contact',
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw Exception('Message is required');
    }
    final resolvedId = businessId?.trim();
    final useBusinessId = resolvedId != null && resolvedId.isNotEmpty && resolvedId != 'local';
    final res = await _db.functions.invoke(
      'notify-store-inquiry',
      body: {
        if (useBusinessId) 'business_id': resolvedId,
        if (!useBusinessId && businessSlug?.trim().isNotEmpty == true)
          'business_slug': normalizeSlug(businessSlug!),
        'message': trimmed,
        if (customerName != null && customerName.trim().isNotEmpty) 'customer_name': customerName.trim(),
        if (customerPhone != null && customerPhone.trim().isNotEmpty) 'customer_phone': customerPhone.trim(),
        if (customerEmail != null && customerEmail.trim().isNotEmpty) 'customer_email': customerEmail.trim(),
        'channel': channel,
      },
    );
    if (res.status >= 400) {
      final err = res.data is Map ? (res.data as Map)['error']?.toString() : res.data?.toString();
      throw Exception(err ?? 'Failed to send inquiry');
    }
    if (res.data is Map) {
      final result = StoreInquiryResult.fromJson(Map<String, dynamic>.from(res.data as Map));
      if (!result.ok) {
        throw Exception(result.warning ?? 'Failed to send inquiry');
      }
      return result;
    }
    return const StoreInquiryResult(ok: true, emailSent: false);
  }

  static int _countUniqueCustomers(
    List<Map<String, dynamic>> orders,
    List<Map<String, dynamic>> appointments,
  ) {
    final keys = <String>{};
    void addRow(Map<String, dynamic> row) {
      final uid = row['customer_user_id']?.toString().trim();
      final phone = row['customer_phone']?.toString().trim();
      final email = row['customer_email']?.toString().trim().toLowerCase();
      final name = row['customer_name']?.toString().trim();
      if (uid != null && uid.isNotEmpty) {
        keys.add('u:$uid');
      } else if (phone != null && phone.isNotEmpty) {
        keys.add('p:$phone');
      } else if (email != null && email.isNotEmpty) {
        keys.add('e:$email');
      } else if (name != null && name.isNotEmpty) {
        keys.add('n:$name');
      }
    }

    for (final row in orders) {
      addRow(row);
    }
    for (final row in appointments) {
      addRow(row);
    }
    return keys.length;
  }
}
