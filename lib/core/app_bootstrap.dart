import 'dart:async';

import 'accessibility_settings.dart';
import 'app_locale.dart';
import 'app_theme_mode.dart';
import 'catalog_store.dart';
import 'customer_profile_store.dart';
import 'customer_appointments_store.dart';
import 'manager_notifications_store.dart';
import 'manager_credentials_store.dart';
import 'manager_store.dart';
import 'manager_subscription_store.dart';
import 'order_restrictions_store.dart';
import 'policy_consent_store.dart';
import 'push/deal_push_service.dart';
import 'store_deep_links.dart';
import 'store_scoped_reload.dart';
import 'store_terms_store.dart';
import 'supabase/supabase_bootstrap.dart';
import '../saas/data/saas_repository.dart';
import '../saas/utils/slug_utils.dart';

/// Splits startup into a fast first frame and deferred background work.
abstract final class AppBootstrap {
  static var _deferredStarted = false;

  /// Local prefs + theme/locale only — must finish before [runApp].
  static Future<void> loadCritical() async {
    final supabaseInit = SupabaseBootstrap.init();
    await Future.wait([
      AppLocale.instance.load(),
      AppThemeController.instance.load(),
      AccessibilitySettings.instance.load(),
      ManagerStore.instance.load(),
      CatalogStore.instance.load(),
      PolicyConsentStore.instance.load(),
      CustomerProfileStore.instance.load(),
      supabaseInit,
    ]);
  }

  /// Network + secondary stores — run once after the first frame.
  static void startDeferredServices() {
    if (_deferredStarted) return;
    _deferredStarted = true;
    unawaited(_runDeferred());
  }

  static Future<void> _runDeferred() async {
    final supabaseInit = SupabaseBootstrap.init();
    unawaited(_prefetchManagerBusiness(supabaseInit));

    await Future.wait([
      OrderRestrictionsStore.instance.load(),
      CustomerAppointmentsStore.instance.load(),
      ManagerNotificationsStore.instance.load(),
      ManagerSubscriptionStore.instance.load(),
      supabaseInit,
    ]);

    await Future.wait([
      ManagerStore.instance.refreshStoreContactEmail(),
      ManagerStore.instance.ensureDemoCatalogReady(),
      ManagerStore.instance.ensureDemoStoreLinked(),
      StoreTermsStore.instance.loadForCurrentStore(),
    ]);

    await reloadStoreScopedData();

    await StoreDeepLinks.init();
    await DealPushService.init();
  }

  static Future<void> _prefetchManagerBusiness(Future<void> supabaseInit) async {
    await supabaseInit;
    if (!SupabaseBootstrap.isReady) return;

    final saved = await ManagerCredentialsStore.instance.load();
    final slug = saved?.slug ?? ManagerStore.instance.linkedBusinessSlug;
    if (slug == null || slug.trim().isEmpty) return;

    unawaited(SaasRepository.instance.fetchBusinessBySlug(normalizeSlug(slug)));
  }
}
