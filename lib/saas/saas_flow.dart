import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_locale.dart';
import '../core/app_theme_mode.dart';
import '../core/demo_store.dart';
import '../core/bakery_navigator.dart';
import '../core/keyboard_safe.dart';
import '../core/manager_store.dart';
import '../core/store_terms_store.dart';
import '../core/public_store_links.dart';
import '../widgets/bakery_sheet_close_bar.dart';
import '../core/supabase/supabase_bootstrap.dart';
import 'data/saas_repository.dart';
import 'models/saas_models.dart';
import 'screens/create_store_screen.dart';
import 'screens/owner_dashboard_screen.dart';
import 'screens/phone_verification_screen.dart';
import 'screens/saas_auth_screen.dart';
import 'utils/slug_utils.dart';
import 'widgets/super_admin_gate.dart';

enum _ManagerStoreEntryChoice { create, existing, continueLinked }

void _popStoreEntryChoice(BuildContext dialogContext, _ManagerStoreEntryChoice choice) {
  popRouteSafely(dialogContext, choice);
}

/// After manager password — pick new store, existing store, or continue with linked slug.
Future<bool> runManagerLoginStoreEntry(BuildContext context) async {
  final root = bakeryRootContext ?? context;

  while (root.mounted) {
    await waitForNavigatorSettle();
    if (!root.mounted) return false;

    final choice = await _showManagerStoreEntryChooser(root);
    if (choice == null || !root.mounted) return false;

    await waitForNavigatorSettle();
    if (!root.mounted) return false;

    switch (choice) {
      case _ManagerStoreEntryChoice.create:
        await openSaasCreateStoreFlow(root);
        return true;
      case _ManagerStoreEntryChoice.existing:
        final linked = await promptLinkExistingStoreForManager(root);
        if (linked) return true;
        continue;
      case _ManagerStoreEntryChoice.continueLinked:
        return true;
    }
  }
  return false;
}

Future<_ManagerStoreEntryChoice?> _showManagerStoreEntryChooser(BuildContext context) async {
  final strings = AppLocale.instance.s;
  final linked = ManagerStore.instance.linkedBusinessSlug?.trim();

  return showBakeryDialog<_ManagerStoreEntryChoice>(
    context: context,
    showCloseButton: false,
    child: Builder(
      builder: (dialogContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.managerLoginStoreChoiceTitle,
                textAlign: TextAlign.center,
                style: BakeryTheme.text(dialogContext, fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                strings.managerLoginStoreChoiceHint,
                textAlign: TextAlign.center,
                style: BakeryTheme.subtitleText(dialogContext, fontSize: 14, height: 1.35),
              ),
              const SizedBox(height: 20),
              if (linked != null && linked.isNotEmpty) ...[
                FilledButton.icon(
                  onPressed: () => _popStoreEntryChoice(
                    dialogContext,
                    _ManagerStoreEntryChoice.continueLinked,
                  ),
                  icon: const Icon(Icons.dashboard_outlined),
                  label: Text(strings.managerLoginContinueLinked),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.managerLoginContinueLinkedSub(linked),
                  textAlign: TextAlign.center,
                  style: BakeryTheme.subtitleText(dialogContext, fontSize: 13),
                ),
                const SizedBox(height: 14),
              ],
              FilledButton.icon(
                onPressed: () => _popStoreEntryChoice(
                  dialogContext,
                  _ManagerStoreEntryChoice.create,
                ),
                icon: const Icon(Icons.add_business_outlined),
                label: Text(strings.managerLoginCreateStore),
              ),
              const SizedBox(height: 8),
              Text(
                strings.managerLoginCreateStoreSub,
                textAlign: TextAlign.center,
                style: BakeryTheme.subtitleText(dialogContext, fontSize: 12),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => _popStoreEntryChoice(
                  dialogContext,
                  _ManagerStoreEntryChoice.existing,
                ),
                icon: const Icon(Icons.login_rounded),
                label: Text(strings.managerLoginExistingStore),
              ),
              const SizedBox(height: 8),
              Text(
                strings.managerLoginExistingStoreSub,
                textAlign: TextAlign.center,
                style: BakeryTheme.subtitleText(dialogContext, fontSize: 12),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _popStoreEntryChoice(
                  dialogContext,
                  _ManagerStoreEntryChoice.create,
                ),
                icon: const Icon(Icons.storefront_outlined),
                label: Text(strings.managerLoginOpenStore),
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// Links manager panel to an existing store by slug (Supabase lookup or local slug).
Future<bool> promptLinkExistingStoreForManager(BuildContext context) async {
  final strings = AppLocale.instance.s;
  final host = bakeryRootContext ?? context;
  if (!host.mounted) return false;

  final controller = TextEditingController(
    text: ManagerStore.instance.linkedBusinessSlug ?? DemoStore.slug,
  );

  final saved = await showDialog<bool>(
    context: host,
    builder: (ctx) => AlertDialog(
      title: Text(strings.managerLoginExistingStore),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.managerLoginExistingStoreSub,
              style: BakeryTheme.subtitleText(ctx, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: strings.managerShareStoreSlugField,
                border: const OutlineInputBorder(),
              ),
              textDirection: TextDirection.ltr,
              autocorrect: false,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => popRouteSafely(ctx, false), child: Text(strings.cancel)),
        FilledButton(
          onPressed: () => popRouteSafely(ctx, true),
          child: Text(strings.login),
        ),
      ],
    ),
  );

  await waitForNavigatorSettle();

  final slugText = normalizeSlug(controller.text);
  controller.dispose();
  if (saved != true || !host.mounted) return false;
  if (slugText.isEmpty) {
    if (host.mounted) {
      ScaffoldMessenger.of(host).showSnackBar(
        SnackBar(content: Text(strings.managerShareStoreSlugField)),
      );
    }
    return false;
  }

  if (SupabaseBootstrap.isReady) {
    try {
      final business = await SaasRepository.instance.fetchBusinessBySlug(slugText);
      if (!host.mounted) return false;
      if (business == null) {
        ScaffoldMessenger.of(host).showSnackBar(
          SnackBar(content: Text(strings.managerLoginExistingNotFound)),
        );
        return false;
      }
      await ManagerStore.instance.linkOnlineBusiness(
        id: business.id,
        slug: business.slug,
        storeMode: business.storeMode,
      );
      await ManagerStore.instance.applyServerBranding(logoUrl: business.logoUrl);
      await StoreTermsStore.instance.loadForSlug(business.slug);
      if (!host.mounted) return false;
      ScaffoldMessenger.of(host).showSnackBar(
        SnackBar(content: Text(strings.managerLoginLinkedOk)),
      );
      return true;
    } catch (e) {
      if (!host.mounted) return false;
      ScaffoldMessenger.of(host).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      return false;
    }
  }

  final ok = await ManagerStore.instance.setShareSlug(slugText);
  if (!host.mounted) return false;
  if (!ok) {
    ScaffoldMessenger.of(host).showSnackBar(
      SnackBar(content: Text(strings.managerShareStoreSlugField)),
    );
    return false;
  }
  await StoreTermsStore.instance.loadForSlug(slugText);
  if (!host.mounted) return false;
  ScaffoldMessenger.of(host).showSnackBar(
    SnackBar(content: Text(strings.managerLoginLinkedOk)),
  );
  return true;
}

/// Manager dashboard / share — open sheet or guide setup.
Future<void> openManagerShareFlow(BuildContext context) async {
  var slug = await _resolveManagerShareSlug();
  if (!context.mounted) return;

  if (slug != null && slug.isNotEmpty) {
    await showStoreShareSheet(context, slug);
    return;
  }

  await _showShareSetupChooser(context);
}

/// Tries linked slug, owned business, then demo store link.
Future<String?> _resolveManagerShareSlug() async {
  var slug = ManagerStore.instance.linkedBusinessSlug?.trim();
  if (slug != null && slug.isNotEmpty) return slug;

  if (!SupabaseBootstrap.isReady) return null;

  final repo = SaasRepository.instance;
  if (repo.currentUser != null) {
    try {
      final owned = await repo.fetchOwnedBusiness();
      if (owned != null) {
        await ManagerStore.instance.linkOnlineBusiness(
          id: owned.id,
          slug: owned.slug,
          storeMode: owned.storeMode,
        );
        return owned.slug;
      }
    } catch (_) {}
  }

  final linkedDemo = await ManagerStore.instance.ensureDemoStoreLinked();
  if (linkedDemo) {
    return ManagerStore.instance.linkedBusinessSlug?.trim();
  }
  return null;
}

Future<void> _showShareSetupChooser(BuildContext context) async {
  final strings = AppLocale.instance.s;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: (sheetCtx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BakerySheetCloseBar(title: strings.managerShareStoreNoSupabaseTitle),
              const SizedBox(height: 4),
              Text(
                strings.managerShareStoreNoLink,
                style: BakeryTheme.subtitleText(sheetCtx, fontSize: 14, height: 1.35),
              ),
              const SizedBox(height: 16),
              if (SupabaseBootstrap.isReady)
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    openSaasCreateStoreFlow(context);
                  },
                  icon: const Icon(Icons.storefront_outlined),
                  label: Text(strings.managerShareSetupOnline),
                ),
              if (SupabaseBootstrap.isReady) const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  _showManualShareSlugDialog(context);
                },
                icon: const Icon(Icons.link_rounded),
                label: Text(strings.managerShareSetupManualSlug),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _showManualShareSlugDialog(BuildContext context) async {
  final strings = AppLocale.instance.s;
  final controller = TextEditingController(text: DemoStore.slug);
  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(strings.managerShareStoreNoSupabaseTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(strings.managerShareStoreNoSupabaseBody, style: BakeryTheme.subtitleText(ctx, height: 1.4)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: strings.managerShareStoreSlugField,
                border: const OutlineInputBorder(),
              ),
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(strings.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(strings.managerShareStoreSlugSave),
        ),
      ],
    ),
  );
  final slugText = controller.text;
  controller.dispose();
  if (saved != true || !context.mounted) return;
  final ok = await ManagerStore.instance.setShareSlug(slugText);
  if (!context.mounted) return;
  if (!ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.managerShareStoreSlugField)),
    );
    return;
  }
  final linked = ManagerStore.instance.linkedBusinessSlug;
  if (linked != null && linked.isNotEmpty) {
    await showStoreShareSheet(context, linked);
  }
}

/// Entry from Settings → Create Store.
Future<void> openSaasCreateStoreFlow(BuildContext context) async {
  if (!SupabaseBootstrap.isReady) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocale.instance.s.managerShareStoreSupabaseSnack)),
    );
    return;
  }

  final repo = SaasRepository.instance;
  if (repo.currentUser == null) {
    final signedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SaasAuthScreen()),
    );
    if (signedIn != true || !context.mounted) return;
  }

  var profile = await repo.fetchCurrentProfile();
  if (!context.mounted) return;

  if (profile == null) {
    final signedIn = repo.currentUser != null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          signedIn
              ? 'Could not load your profile. Sign out, sign in again with shilohdhd1@gmail.com, then retry.'
              : 'Please sign in first (Settings → Create Store).',
        ),
        duration: const Duration(seconds: 6),
      ),
    );
    return;
  }

  if (!profile.phoneVerified) {
    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PhoneVerificationScreen()),
    );
    if (verified != true || !context.mounted) return;
    profile = await repo.fetchCurrentProfile();
  }

  if (!context.mounted) return;

  if (profile?.isSuperAdmin == true) {
    final goAdmin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Super Admin'),
        content: const Text('Open Super Admin dashboard or continue creating a store?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Super Admin')),
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Create Store')),
        ],
      ),
    );
    if (goAdmin == true && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SuperAdminGate()),
      );
      return;
    }
  }

  final existing = await repo.fetchOwnedBusiness();
  if (!context.mounted) return;
  if (existing != null) {
    await ManagerStore.instance.linkOnlineBusiness(
      id: existing.id,
      slug: existing.slug,
      storeMode: existing.storeMode,
    );
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OwnerDashboardScreen(business: existing)),
    );
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const CreateStoreScreen()),
  );
}

String storeShareMessageText(String slug) {
  final link = PublicStoreLinks.publicUrlForSlug(slug);
  final he = AppLocale.instance.isHebrew;
  return he ? 'בקרו בחנות שלנו: $link' : 'Visit our store: $link';
}

Future<void> _showShareLaunchFailed(BuildContext context) async {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocale.instance.s.managerShareStoreLaunchFailed)),
  );
}

Future<bool> _launchShareUri(Uri uri) async {
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> copyStoreLink(BuildContext context, String slug) async {
  final link = PublicStoreLinks.publicUrlForSlug(slug);
  await Clipboard.setData(ClipboardData(text: link));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocale.instance.s.managerShareStoreLinkCopied(link))),
    );
  }
}

Future<void> shareStoreLinkWhatsApp(BuildContext context, String slug) async {
  final msg = Uri.encodeComponent(storeShareMessageText(slug));
  final uri = Uri.parse('https://wa.me/?text=$msg');
  if (!await _launchShareUri(uri) && context.mounted) {
    await _showShareLaunchFailed(context);
  }
}

Future<void> shareStoreLinkEmail(BuildContext context, String slug) async {
  final he = AppLocale.instance.isHebrew;
  final subject = Uri.encodeComponent(he ? 'חנות שלנו' : 'Our store');
  final body = Uri.encodeComponent(storeShareMessageText(slug));
  final uri = Uri.parse('mailto:?subject=$subject&body=$body');
  if (!await _launchShareUri(uri) && context.mounted) {
    await _showShareLaunchFailed(context);
  }
}

Future<void> shareStoreLinkSms(BuildContext context, String slug) async {
  final body = Uri.encodeComponent(storeShareMessageText(slug));
  final uri = Uri.parse('sms:?body=$body');
  if (!await _launchShareUri(uri) && context.mounted) {
    await _showShareLaunchFailed(context);
  }
}

Future<void> shareStoreLinkTelegram(BuildContext context, String slug) async {
  final link = PublicStoreLinks.publicUrlForSlug(slug);
  final text = Uri.encodeComponent(storeShareMessageText(slug));
  final url = Uri.encodeComponent(link);
  final uri = Uri.parse('https://t.me/share/url?url=$url&text=$text');
  if (!await _launchShareUri(uri) && context.mounted) {
    await _showShareLaunchFailed(context);
  }
}

Future<void> shareStoreLinkFacebook(BuildContext context, String slug) async {
  final link = Uri.encodeComponent(PublicStoreLinks.publicUrlForSlug(slug));
  final uri = Uri.parse('https://www.facebook.com/sharer/sharer.php?u=$link');
  if (!await _launchShareUri(uri) && context.mounted) {
    await _showShareLaunchFailed(context);
  }
}

Future<void> shareStoreLinkX(BuildContext context, String slug) async {
  final text = Uri.encodeComponent(storeShareMessageText(slug));
  final uri = Uri.parse('https://twitter.com/intent/tweet?text=$text');
  if (!await _launchShareUri(uri) && context.mounted) {
    await _showShareLaunchFailed(context);
  }
}

Future<void> shareStoreLinkSystem(BuildContext context, String slug) async {
  final message = storeShareMessageText(slug);
  final result = await Share.share(message, subject: AppLocale.instance.isHebrew ? 'חנות שלנו' : 'Our store');
  if (result.status == ShareResultStatus.unavailable && context.mounted) {
    await copyStoreLink(context, slug);
  }
}

Future<void> showStoreShareSheet(BuildContext context, String slug) async {
  final strings = AppLocale.instance.s;
  final link = PublicStoreLinks.publicUrlForSlug(slug);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: (sheetCtx) {
      void closeThen(Future<void> Function() action) {
        Navigator.pop(sheetCtx);
        Future.microtask(() {
          if (context.mounted) action();
        });
      }

      Widget tile({
        required IconData icon,
        required String label,
        required VoidCallback onTap,
      }) {
        return ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          tileColor: BakeryTheme.cardSurface(sheetCtx),
          leading: Icon(icon, color: BakeryTheme.accent(sheetCtx)),
          title: Text(
            label,
            style: BakeryTheme.text(sheetCtx, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          onTap: onTap,
        );
      }

      final bottom = MediaQuery.viewPaddingOf(sheetCtx).bottom;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 12 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BakerySheetCloseBar(title: strings.managerShareStoreSheetTitle),
              const SizedBox(height: 4),
              Text(
                strings.managerShareStoreSheetHint,
                textAlign: TextAlign.center,
                style: BakeryTheme.subtitleText(sheetCtx, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BakeryTheme.softSurface(sheetCtx),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: BakeryTheme.border(sheetCtx)),
                ),
                child: Text(
                  link,
                  style: BakeryTheme.text(sheetCtx, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheetCtx).height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      tile(
                        icon: Icons.link_rounded,
                        label: strings.managerShareStoreCopy,
                        onTap: () => closeThen(() => copyStoreLink(context, slug)),
                      ),
                      const SizedBox(height: 8),
                      tile(
                        icon: Icons.chat_rounded,
                        label: strings.managerShareStoreWhatsApp,
                        onTap: () => closeThen(() => shareStoreLinkWhatsApp(context, slug)),
                      ),
                      const SizedBox(height: 8),
                      tile(
                        icon: Icons.mail_outline_rounded,
                        label: strings.managerShareStoreEmail,
                        onTap: () => closeThen(() => shareStoreLinkEmail(context, slug)),
                      ),
                      const SizedBox(height: 8),
                      tile(
                        icon: Icons.sms_outlined,
                        label: strings.managerShareStoreSms,
                        onTap: () => closeThen(() => shareStoreLinkSms(context, slug)),
                      ),
                      const SizedBox(height: 8),
                      tile(
                        icon: Icons.send_rounded,
                        label: strings.managerShareStoreTelegram,
                        onTap: () => closeThen(() => shareStoreLinkTelegram(context, slug)),
                      ),
                      const SizedBox(height: 8),
                      tile(
                        icon: Icons.facebook_rounded,
                        label: strings.managerShareStoreFacebook,
                        onTap: () => closeThen(() => shareStoreLinkFacebook(context, slug)),
                      ),
                      const SizedBox(height: 8),
                      tile(
                        icon: Icons.tag_rounded,
                        label: strings.managerShareStoreX,
                        onTap: () => closeThen(() => shareStoreLinkX(context, slug)),
                      ),
                      const SizedBox(height: 8),
                      tile(
                        icon: Icons.share_rounded,
                        label: strings.managerShareStoreMore,
                        onTap: () => closeThen(() => shareStoreLinkSystem(context, slug)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> shareStoreWhatsApp(BuildContext context, SaasBusiness business) async {
  await shareStoreLinkWhatsApp(context, business.slug);
}
