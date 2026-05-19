import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/manager_store.dart';
import '../core/public_store_links.dart';
import '../core/supabase/supabase_bootstrap.dart';
import 'data/saas_repository.dart';
import 'models/saas_models.dart';
import 'screens/create_store_screen.dart';
import 'screens/owner_dashboard_screen.dart';
import 'screens/phone_verification_screen.dart';
import 'screens/saas_auth_screen.dart';
import 'widgets/super_admin_gate.dart';

/// Entry from Settings → Create Store.
Future<void> openSaasCreateStoreFlow(BuildContext context) async {
  if (!SupabaseBootstrap.isReady) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.',
        ),
      ),
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

Future<void> copyStoreLink(BuildContext context, String slug) async {
  final link = PublicStoreLinks.publicUrlForSlug(slug);
  await Clipboard.setData(ClipboardData(text: link));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Link copied: $link')),
    );
  }
}

Future<void> shareStoreWhatsApp(BuildContext context, SaasBusiness business) async {
  final link = PublicStoreLinks.publicUrlForSlug(business.slug);
  final msg = Uri.encodeComponent('Visit our store: $link');
  final uri = Uri.parse('https://wa.me/?text=$msg');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
