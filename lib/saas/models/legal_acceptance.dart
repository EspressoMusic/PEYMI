class LegalAcceptance {
  const LegalAcceptance({
    required this.userId,
    required this.acceptedTermsAt,
    required this.acceptedPrivacyAt,
    required this.termsVersion,
    required this.privacyVersion,
    required this.createdAt,
  });

  final String userId;
  final DateTime acceptedTermsAt;
  final DateTime acceptedPrivacyAt;
  final String termsVersion;
  final String privacyVersion;
  final DateTime createdAt;

  factory LegalAcceptance.fromJson(Map<String, dynamic> json) {
    return LegalAcceptance(
      userId: json['user_id'] as String,
      acceptedTermsAt: DateTime.parse(json['accepted_terms_at'] as String),
      acceptedPrivacyAt: DateTime.parse(json['accepted_privacy_at'] as String),
      termsVersion: json['terms_version'] as String,
      privacyVersion: json['privacy_version'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool coversCurrentVersions({
    required String termsVersion,
    required String privacyVersion,
  }) =>
      this.termsVersion == termsVersion && this.privacyVersion == privacyVersion;
}
