import 'package:flutter/material.dart';

import '../core/app_locale.dart';
import '../core/app_theme_mode.dart';
import 'legal_document_screen.dart';

/// Privacy Policy + Terms of Use links for auth / settings screens.
class LegalLinksRow extends StatelessWidget {
  const LegalLinksRow({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocale.instance.s;
    final style = BakeryTheme.text(context, fontSize: 14).copyWith(
      color: BakeryTheme.accent(context),
      decoration: TextDecoration.underline,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => LegalDocumentScreen.open(context, LegalDocumentKind.privacy),
            child: Text(strings.legalPrivacyPolicy, style: style),
          ),
          Text('·', style: BakeryTheme.subtitleText(context, fontSize: 14)),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => LegalDocumentScreen.open(context, LegalDocumentKind.terms),
            child: Text(strings.legalTermsOfUse, style: style),
          ),
        ],
      ),
    );
  }
}
