import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/accessibility_settings.dart';
import '../core/app_locale.dart';
import '../core/app_theme_mode.dart';
import '../core/keyboard_safe.dart';
import '../core/legal_config.dart';

/// Accessibility controls + statement (customer settings & manager panel).
Future<void> showAccessibilityPanel(BuildContext context) async {
  final strings = AppLocale.instance.s;
  final he = AppLocale.instance.isHebrew;
  final a11y = AccessibilitySettings.instance;
  final businessName = LegalConfig.businessDisplayName(he);
  final email = LegalConfig.accessibilityEmail;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: (sheetContext) {
      final bottom = MediaQuery.viewPaddingOf(sheetContext).bottom;
      return bakeryModalSheetFrame(
        sheetContext,
        ListenableBuilder(
          listenable: a11y,
          builder: (context, _) {
            final percent = (a11y.textScale * 100).round();
            return ListView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    strings.accessibilityTitle,
                    textAlign: TextAlign.center,
                    style: BakeryTheme.text(sheetContext, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 14),
                _A11yPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        strings.textSize,
                        textAlign: TextAlign.center,
                        style: BakeryTheme.text(sheetContext, fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$percent%',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: BakeryTheme.body(sheetContext),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _A11yActionChip(
                              label: strings.decreaseText,
                              icon: Icons.text_decrease,
                              onPressed: a11y.decreaseText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _A11yActionChip(
                              label: strings.resetTextSize,
                              icon: Icons.restart_alt,
                              onPressed: a11y.resetText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _A11yActionChip(
                              label: strings.increaseText,
                              icon: Icons.text_increase,
                              primary: true,
                              onPressed: a11y.increaseText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  strings.accessibilityBody(email, businessName),
                  style: TextStyle(fontSize: 14, height: 1.45, color: BakeryTheme.subtitle(sheetContext)),
                ),
                if (LegalConfig.accessibilityStatementUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    button: true,
                    label: strings.accessibilityWebLink,
                    child: TextButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(LegalConfig.accessibilityStatementUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(strings.accessibilityWebLink),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        title: strings.accessibilityTitle,
      );
    },
  );
}

class _A11yPanel extends StatelessWidget {
  const _A11yPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: BakeryTheme.softSurface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BakeryTheme.border(context), width: 1.2),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))]
            : const [
                BoxShadow(color: Color(0x38000000), blurRadius: 16, offset: Offset(0, 8)),
              ],
      ),
      child: child,
    );
  }
}

class _A11yActionChip extends StatelessWidget {
  const _A11yActionChip({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: primary ? scheme.primary.withValues(alpha: 0.15) : BakeryTheme.cardSurface(context),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            child: Column(
              children: [
                Icon(icon, color: primary ? scheme.primary : BakeryTheme.muted(context)),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: BakeryTheme.body(context)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
