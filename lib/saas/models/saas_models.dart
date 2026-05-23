class SaasProfile {
  const SaasProfile({
    required this.id,
    this.email,
    this.fullName,
    this.phone,
    required this.phoneVerified,
    this.phoneVerifiedAt,
    required this.role,
  });

  final String id;
  final String? email;
  final String? fullName;
  final String? phone;
  final bool phoneVerified;
  final DateTime? phoneVerifiedAt;
  final String role;

  factory SaasProfile.fromJson(Map<String, dynamic> json) {
    return SaasProfile(
      id: json['id'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      phoneVerified: json['phone_verified'] as bool? ?? false,
      phoneVerifiedAt: json['phone_verified_at'] != null
          ? DateTime.tryParse(json['phone_verified_at'] as String)
          : null,
      role: json['role'] as String? ?? 'customer',
    );
  }

  bool get isSuperAdmin => role == 'super_admin';
  bool get isBusinessOwner => role == 'business_owner';
}

class SaasBusiness {
  const SaasBusiness({
    required this.id,
    required this.ownerId,
    required this.businessName,
    required this.slug,
    this.description,
    this.logoUrl,
    this.phone,
    this.businessType,
    this.address,
    required this.subscriptionStatus,
    required this.isActive,
    this.pastDueGraceUntil,
    this.storeMode = 'products',
    this.storeTerms,
  });

  final String id;
  final String ownerId;
  final String businessName;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? phone;
  final String? businessType;
  final String? address;
  final String subscriptionStatus;
  final bool isActive;
  final DateTime? pastDueGraceUntil;
  final String storeMode;
  final String? storeTerms;

  factory SaasBusiness.fromJson(Map<String, dynamic> json) {
    return SaasBusiness(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      businessName: json['business_name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      phone: json['phone'] as String?,
      businessType: json['business_type'] as String?,
      address: json['address'] as String?,
      subscriptionStatus: json['subscription_status'] as String? ?? 'trial',
      isActive: json['is_active'] as bool? ?? true,
      pastDueGraceUntil: json['past_due_grace_until'] != null
          ? DateTime.tryParse(json['past_due_grace_until'] as String)
          : null,
      storeMode: json['store_mode'] as String? ?? 'products',
      storeTerms: json['store_terms'] as String?,
    );
  }

  bool get isAppointmentMode => storeMode == 'appointments';
  bool get isProductMode => storeMode == 'products';

  bool get acceptsCustomers {
    if (!isActive) return false;
    if (subscriptionStatus == 'suspended' || subscriptionStatus == 'cancelled') {
      return false;
    }
    if (subscriptionStatus == 'past_due') {
      if (pastDueGraceUntil == null) return true;
      return pastDueGraceUntil!.isAfter(DateTime.now());
    }
    return subscriptionStatus == 'trial' || subscriptionStatus == 'active';
  }

  bool get isPubliclyVisible {
    if (!isActive) return false;
    return subscriptionStatus != 'suspended' && subscriptionStatus != 'cancelled';
  }

  bool get ownerDashboardUnlocked {
    if (!isActive) return false;
    return subscriptionStatus == 'trial' ||
        subscriptionStatus == 'active' ||
        subscriptionStatus == 'past_due';
  }
}

class SaasProduct {
  const SaasProduct({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.isActive,
  });

  final String id;
  final String businessId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isActive;

  factory SaasProduct.fromJson(Map<String, dynamic> json) {
    return SaasProduct(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class SaasBusinessAdminRow {
  const SaasBusinessAdminRow({
    required this.business,
    this.ownerEmail,
    this.productCount = 0,
    this.orderCount = 0,
    this.appointmentCount = 0,
  });

  final SaasBusiness business;
  final String? ownerEmail;
  final int productCount;
  final int orderCount;
  final int appointmentCount;
}
