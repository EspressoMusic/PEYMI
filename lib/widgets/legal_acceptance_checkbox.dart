import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/app_locale.dart';
import '../core/app_theme_mode.dart';
import 'legal_document_screen.dart';

/// Required before creating a business on Peymiz.
class LegalAcceptanceCheckbox extends StatelessWidget {
  const LegalAcceptanceCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocale.instance.s;
    final linkStyle = BakeryTheme.text(context, fontSize: 14, height: 1.35).copyWith(
      color: BakeryTheme.accent(context),
      decoration: TextDecoration.underline,
    );

    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: RichText(
        text: TextSpan(
          style: BakeryTheme.text(context, fontSize: 14, height: 1.35),
          children: [
            TextSpan(text: strings.legalAcceptPrefix),
            TextSpan(
              text: strings.legalTermsLink,
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => LegalDocumentScreen.open(context, LegalDocumentKind.terms),
            ),
            TextSpan(text: strings.legalAcceptMiddle),
            TextSpan(
              text: strings.legalPrivacyLink,
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => LegalDocumentScreen.open(context, LegalDocumentKind.privacy),
            ),
            TextSpan(text: strings.legalAcceptSuffix),
          ],
        ),
      ),
    );
  }
}
