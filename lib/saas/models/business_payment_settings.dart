/// How customers pay the [business] owner (not Peymiz subscription billing).
///
/// Future: Stripe Connect, Grow/Meshulam, webhooks, commission — see [docs/PAYMENT_INTEGRATION_TODO.md].
class BusinessPaymentSettings {
  const BusinessPaymentSettings({
    required this.businessId,
    required this.paymentEnabled,
    required this.paymentMode,
    required this.currency,
    this.paymentInstructions,
    this.externalPaymentLink,
    this.paymentPhone,
    this.createdAt,
    this.updatedAt,
  });

  final String businessId;
  final bool paymentEnabled;
  final String paymentMode;
  final String currency;
  final String? paymentInstructions;
  final String? externalPaymentLink;
  final String? paymentPhone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BusinessPaymentSettings.fromJson(Map<String, dynamic> json) {
    return BusinessPaymentSettings(
      businessId: json['business_id'] as String,
      paymentEnabled: json['payment_enabled'] as bool? ?? false,
      paymentMode: json['payment_mode'] as String? ?? 'manual',
      currency: (json['currency'] as String?)?.trim().isNotEmpty == true
          ? (json['currency'] as String).trim()
          : 'USD',
      paymentInstructions: json['payment_instructions'] as String?,
      externalPaymentLink: json['external_payment_link'] as String?,
      paymentPhone: json['payment_phone'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toUpsertJson() {
    return {
      'business_id': businessId,
      'payment_enabled': paymentEnabled,
      'payment_mode': paymentMode,
      'currency': currency,
      'payment_instructions': paymentInstructions?.trim().isEmpty == true
          ? null
          : paymentInstructions?.trim(),
      'external_payment_link': externalPaymentLink?.trim().isEmpty == true
          ? null
          : externalPaymentLink?.trim(),
      'payment_phone': paymentPhone?.trim().isEmpty == true ? null : paymentPhone?.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  bool get showsInstructionsToCustomer =>
      paymentEnabled &&
      (paymentInstructions?.trim().isNotEmpty == true ||
          externalPaymentLink?.trim().isNotEmpty == true ||
          paymentPhone?.trim().isNotEmpty == true);

  static const modes = [
    'manual',
    'external_link',
    'cash_on_delivery',
    'pay_on_arrival',
    'future_provider',
  ];
}
