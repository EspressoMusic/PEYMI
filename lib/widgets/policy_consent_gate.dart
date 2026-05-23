import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_locale.dart';
import '../core/app_theme_mode.dart';
import '../core/keyboard_safe.dart';
import '../core/legal_documents.dart';
import '../core/policy_consent_store.dart';
import '../core/store_terms_store.dart';
import 'policy_video_banner.dart';

/// Blocks [child] until the user accepts terms — compact bottom banner only (full text on demand).
class PolicyConsentGate extends StatelessWidget {
  const PolicyConsentGate({
    super.key,
    required this.audience,
    required this.child,
  });

  final PolicyAudience audience;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PolicyConsentStore.instance,
      builder: (context, _) {
        final store = PolicyConsentStore.instance;
        final pending = store.isLoaded && !store.hasAccepted(audience);

        return Stack(
          children: [
            child,
            if (pending)
              Positioned.fill(
                child: PopScope(
                  canPop: false,
                  child: _PolicyConsentBanner(
                    audience: audience,
                    onAccept: () => PolicyConsentStore.instance.accept(audience),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PolicyConsentBanner extends StatelessWidget {
  const _PolicyConsentBanner({
    required this.audience,
    required this.onAccept,
  });

  final PolicyAudience audience;
  final VoidCallback onAccept;

  Future<void> _showFullTerms(BuildContext context) async {
    final strings = AppLocale.instance.s;
    final isOwner = audience == PolicyAudience.owner;
    final hebrew = AppLocale.instance.isHebrew;
    final platformTerms = isOwner
        ? LegalDocuments.privacyAndTermsOwner(hebrew)
        : LegalDocuments.privacyAndTermsCustomer(hebrew);
    final storeTerms = StoreTermsStore.instance.terms.trim();

    await showBakeryDialog<void>(
      context: context,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.policyConsentFullTermsTitle,
              textAlign: TextAlign.center,
              style: BakeryTheme.text(context, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (PolicyConsentStore.policyVideoUrl.trim().isNotEmpty) ...[
                      const PolicyVideoBanner(),
                      const SizedBox(height: 12),
                    ],
                    if (storeTerms.isNotEmpty) ...[
                      Text(
                        strings.storeTerms,
                        style: BakeryTheme.text(context, fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        storeTerms,
                        style: BakeryTheme.text(context, fontSize: 13, height: 1.45),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SelectableText(
                      platformTerms,
                      style: BakeryTheme.subtitleText(context, fontSize: 13, height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocale.instance.s;
    final accent = BakeryTheme.accent(context);

    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Material(
                elevation: 10,
                color: BakeryTheme.cardSurface(context),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        strings.policyConsentTitle,
                        textAlign: TextAlign.center,
                        style: BakeryTheme.text(context, fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${strings.policyConsentBannerBeforeTerms}${strings.policyConsentTermsLink}${strings.policyConsentBannerAfterTerms}',
                        textAlign: TextAlign.center,
                        style: BakeryTheme.subtitleText(context, fontSize: 13, height: 1.35),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: () => _showFullTerms(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            strings.policyConsentReadFull,
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: onAccept,
                        child: Text(strings.policyConsentAccept),
                      ),
                      TextButton(
                        onPressed: () => SystemNavigator.pop(),
                        child: Text(
                          strings.policyConsentExitApp,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
