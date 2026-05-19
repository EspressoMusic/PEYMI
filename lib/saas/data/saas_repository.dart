import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_bootstrap.dart';
import '../models/appointment_models.dart';
import '../models/saas_models.dart';
import '../utils/slug_utils.dart';

class SaasRepository {
  SaasRepository._();
  static final SaasRepository instance = SaasRepository._();

  SupabaseClient get _db => SupabaseBootstrap.client;

  User? get currentUser => _db.auth.currentUser;

  Stream<AuthState> get authStateChanges => _db.auth.onAuthStateChange;

  Future<void> signInWithEmail({required String email, required String password}) async {
    await _db.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail({required String email, required String password}) async {
    await _db.auth.signUp(email: email, password: password);
    if (currentUser == null) {
      await _db.auth.signInWithPassword(email: email, password: password);
    }
  }

  Future<void> signOut() => _db.auth.signOut();

  /// Throws if the signed-in user is not [SaasProfile.isSuperAdmin] (enforced via RLS read).
  Future<SaasProfile> requireSuperAdmin() async {
    final profile = await fetchCurrentProfile();
    if (profile == null || !profile.isSuperAdmin) {
      throw Exception('Forbidden');
    }
    return profile;
  }

  Future<SaasProfile?> fetchCurrentProfile({bool createIfMissing = true}) async {
    final uid = currentUser?.id;
    if (uid == null) return null;

    if (createIfMissing) {
      try {
        final ensured = await _db.rpc('ensure_my_profile');
        if (ensured != null) {
          return SaasProfile.fromJson(Map<String, dynamic>.from(ensured as Map));
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
    return SaasProfile.fromJson(Map<String, dynamic>.from(row));
  }

  Future<bool> isSlugAvailable(String slug) async {
    final normalized = normalizeSlug(slug);
    final result = await _db.rpc('is_slug_available', params: {'p_slug': normalized});
    return result == true;
  }

  Future<SaasBusiness?> fetchBusinessBySlug(String slug) async {
    final row = await _db.from('businesses').select().eq('slug', slug).maybeSingle();
    if (row == null) return null;
    return SaasBusiness.fromJson(Map<String, dynamic>.from(row));
  }

  Future<SaasBusiness?> fetchOwnedBusiness() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    final row = await _db
        .from('businesses')
        .select()
        .eq('owner_id', uid)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return SaasBusiness.fromJson(Map<String, dynamic>.from(row));
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
    String? description,
    String? logoUrl,
    String? phone,
    String? businessType,
    String? address,
  }) async {
    final res = await _db.functions.invoke(
      'create-business',
      body: {
        'business_name': businessName,
        'slug': slug,
        if (description != null) 'description': description,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (phone != null) 'phone': phone,
        if (businessType != null) 'business_type': businessType,
        if (address != null) 'address': address,
      },
    );
    if (res.status >= 400) {
      final err = res.data is Map ? (res.data as Map)['error']?.toString() : res.data?.toString();
      throw Exception(err ?? 'Failed to create store');
    }
    return Map<String, dynamic>.from(res.data as Map);
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
      list.add(
        SaasBusinessAdminRow(
          business: business,
          ownerEmail: owner?['email'] as String?,
          productCount: (products as List).length,
          orderCount: (orders as List).length,
          appointmentCount: (appointments as List).length,
        ),
      );
    }
    return list;
  }

  Future<void> superAdminUpdateBusiness({
    required String businessId,
    bool? isActive,
    String? subscriptionStatus,
  }) async {
    await requireSuperAdmin();
    final res = await _db.functions.invoke(
      'super-admin-business',
      body: {
        'business_id': businessId,
        if (isActive != null) 'is_active': isActive,
        if (subscriptionStatus != null) 'subscription_status': subscriptionStatus,
      },
    );
    if (res.status >= 400) {
      final err = res.data is Map ? (res.data as Map)['error']?.toString() : null;
      throw Exception(err ?? 'Update failed');
    }
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
    final patch = <String, dynamic>{};
    if (slotDurationMinutes != null) patch['slot_duration_minutes'] = slotDurationMinutes;
    if (bookingNoticeMinutes != null) patch['booking_notice_minutes'] = bookingNoticeMinutes;
    if (maxDaysAhead != null) patch['max_days_ahead'] = maxDaysAhead;
    if (patch.isEmpty) return;
    await _db.from('business_appointment_settings').update(patch).eq('business_id', businessId);
  }

  static String _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().split('T').first;

  Future<void> sendCustomerMessage({
    required String businessId,
    required String message,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) async {
    await _db.from('customer_messages').insert({
      'business_id': businessId,
      'message': message,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'customer_user_id': currentUser?.id,
    });
  }
}
