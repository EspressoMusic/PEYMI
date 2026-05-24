import 'dart:async';

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
import '../core/store_scoped_reload.dart';
import '../core/store_terms_store.dart';
import '../core/public_store_links.dart';
import '../widgets/bakery_celebration.dart';
import '../widgets/bakery_sheet_close_bar.dart';
import '../widgets/copyable_store_link.dart';
import '../core/supabase/supabase_bootstrap.dart';
import 'data/saas_repository.dart';
import 'models/saas_models.dart';
import 'screens/create_store_screen.dart';
import 'screens/saas_auth_screen.dart';
import 'utils/slug_utils.dart';

/// Links the manager panel to a store by slug (Supabase or local fallback).
Future<bool> linkManagerStoreBySlug(String rawSlug) async {
  final slugText = normalizeSlug(rawSlug);
  if (slugText.isEmpty) return false;
  final isDemo = DemoStore.isDemoSlug(slugText);

  if (SupabaseBootstrap.isReady) {
    try {
      final linkedSlug = ManagerStore.instance.linkedBusinessSlug?.trim().toLowerCase();
      if (ManagerStore.instance.hasLinkedBusiness &&
          (linkedSlug == slugText || (isDemo && DemoStore.isDemoSlug(linkedSlug)))) {
        unawaited(_refreshLinkedStoreExtras(isDemo ? DemoStore.slug : slugText));
        await reloadStoreScopedData();
        return true;
      }

      final business = isDemo
          ? await SaasRepository.instance.fetchDemoBusiness()
          : await SaasRepository.instance.fetchBusinessBySlug(slugText);
      if (business != null) {
        final slugUnchanged = linkedSlug == business.slug.trim().toLowerCase();
        await ManagerStore.instance.linkOnlineBusiness(
          id: business.id,
          slug: business.slug,
          storeMode: business.storeMode,
        );

        final extras = Future.wait([
          ManagerStore.instance.applyServerBranding(logoUrl: business.logoUrl),
          StoreTermsStore.instance.loadForSlug(business.slug),
        ]);
        if (slugUnchanged && ManagerStore.instance.hasLinkedBusiness) {
          unawaited(extras);
        } else {
          await extras;
        }
        await reloadStoreScopedData();
        return true;
      }

      if (isDemo) {
        final linked = await ManagerStore.instance.setShareSlug(DemoStore.slug);
        if (linked) await reloadStoreScopedData();
        return linked;
      }
      return false;
    } catch (_) {
      if (isDemo) {
        final linked = await ManagerStore.instance.setShareSlug(DemoStore.slug);
        if (linked) await reloadStoreScopedData();
        return linked;
      }
      return false;
    }
  }

  if (isDemo) {
    final linked = await ManagerStore.instance.setShareSlug(DemoStore.slug);
    if (linked) await reloadStoreScopedData();
    return linked;
  }
  final linked = await ManagerStore.instance.setShareSlug(slugText);
  if (linked) await reloadStoreScopedData();
  return linked;
}

/// Demo manager login — always links locally; enriches from Supabase when available.
Future<bool> linkDemoStoreForLogin() async {
  if (SupabaseBootstrap.isReady) {
    try {
      final business = await SaasRepository.instance.fetchDemoBusiness();
      if (business != null) {
        await ManagerStore.instance.linkOnlineBusiness(
          id: business.id,
          slug: business.slug,
          storeMode: business.storeMode,
          contactEmail: business.contactEmail ?? DemoStore.defaultContactEmail,
        );
        unawaited(Future.wait([
          ManagerStore.instance.applyServerBranding(logoUrl: business.logoUrl),
          StoreTermsStore.instance.loadForSlug(business.slug),
        ]));
        await reloadStoreScopedData();
        return true;
      }
    } catch (_) {}
  }
  final linked = await ManagerStore.instance.setShareSlug(DemoStore.slug);
  if (linked) {
    await ManagerStore.instance.ensureDemoCatalogReady();
    await reloadStoreScopedData();
  }
  return linked;
}

Future<void> _refreshLinkedStoreExtras(String slug) async {
  try {
    final business = await SaasRepository.instance.fetchBusinessBySlug(slug);
    if (business == null) return;
    await Future.wait([
      ManagerStore.instance.applyServerBranding(logoUrl: business.logoUrl),
      StoreTermsStore.instance.loadForSlug(business.slug),
    ]);
  } catch (_) {}
}

/// After manager password — pick new store, existing store, or continue with linked slug.
Future<bool> runManagerLoginStoreEntry(BuildContext context) async {
  // Store is linked during login; go straight to the manager panel.
  return ManagerStore.instance.hasLinkedBusiness;
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
      unawaited(showBakeryNoticeBanner(host, title: strings.managerShareStoreSlugField, isError: true));
    }
    return false;
  }

  final linked = await linkManagerStoreBySlug(slugText);
  if (!host.mounted) return false;
  if (!linked) {
    unawaited(showBakeryNoticeBanner(host, title: strings.managerLoginExistingNotFound, isError: true));
    return false;
  }
  await showBakeryUpdateBanner(host, title: strings.managerLoginLinkedOk);
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
    unawaited(showBakeryNoticeBanner(context, title: strings.managerShareStoreSlugField, isError: true));
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
    await showBakeryUpdateBanner(context, title: AppLocale.instance.s.managerShareStoreSupabaseSnack);
    return;
  }

  final repo = SaasRepository.instance;
  if (repo.currentUser == null) {
    final signedIn = await pushRouteSafely<bool>(
      MaterialPageRoute(builder: (_) => const SaasAuthScreen()),
    );
    if (signedIn != true || !context.mounted) return;
  }

  await pushRouteSafely(
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
  unawaited(showBakeryNoticeBanner(context, title: AppLocale.instance.s.managerShareStoreLaunchFailed, isError: true));
}

Future<bool> _launchShareUri(Uri uri) async {
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> copyStoreLink(BuildContext context, String slug) async {
  final link = PublicStoreLinks.publicUrlForSlug(slug);
  await Clipboard.setData(ClipboardData(text: link));
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
  final linkKey = GlobalKey<CopyableStoreLinkBlockState>();
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
              CopyableStoreLinkBlock(key: linkKey, link: link, compact: true),
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
                        onTap: () => linkKey.currentState?.copyLink(),
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
