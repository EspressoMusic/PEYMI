import 'app_locale.dart';
import 'manager_store.dart';
import 'public_store_links.dart';

/// Operator / legal contact — override at build: --dart-define=ACCESSIBILITY_EMAIL=...
abstract final class LegalConfig {
  static const privacyEmail = 'privacy@peymiz.com';
  static const supportEmail = 'support@peymiz.com';
  static const accessibilityEmail = String.fromEnvironment(
    'ACCESSIBILITY_EMAIL',
    defaultValue: 'shilohdhd1@gmail.com',
  );

  static const operatorEmail = String.fromEnvironment(
    'OPERATOR_EMAIL',
    defaultValue: 'shilohdhd1@gmail.com',
  );

  static const accessibilityStatementUrl = String.fromEnvironment(
    'ACCESSIBILITY_STATEMENT_URL',
    defaultValue: 'https://bizmi.app/accessibility.html',
  );

  static Uri _legalPageUri(String fileName) {
    final base = PublicStoreLinks.baseUri;
    final prefix = PublicStoreLinks.publicPathPrefix;
    final path = prefix.isEmpty ? '/$fileName' : '$prefix/$fileName';
    return base.replace(path: path);
  }

  static Uri get privacyPolicyUri => _legalPageUri('privacy-policy.html');
  static Uri get termsOfUseUri => _legalPageUri('terms-of-use.html');

  /// Display name for accessibility statement and legal headers.
  static String businessDisplayName(bool hebrew) {
    final slug = ManagerStore.instance.linkedBusinessSlug?.trim();
    if (slug != null && slug.isNotEmpty) {
      return slug;
    }
    final title = AppLocale.instance.s.appTitle;
    if (hebrew && title == 'Peymiz') return 'מאפיית הבית';
    return title;
  }
}
