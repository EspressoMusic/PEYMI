import 'package:flutter/material.dart';

import '../core/app_creator_unlock.dart';
import '../core/app_locale.dart';
import '../core/app_theme_mode.dart';
import '../core/supabase/supabase_bootstrap.dart';
import '../widgets/bakery_celebration.dart';
import 'data/saas_repository.dart';
import 'screens/app_creator_dashboard_screen.dart';

/// Opens the secret programmer panel (4 taps on English in language settings).
Future<void> openProgrammerPanelGate(BuildContext context) => openAppCreatorPasswordGate(context);

Future<void> openAppCreatorPasswordGate(BuildContext context) async {
  if (AppCreatorUnlock.isUnlocked) {
    await _openCreatorDashboard(context);
    return;
  }

  if (SupabaseBootstrap.isReady) {
    try {
      final profile = await SaasRepository.instance.fetchCurrentProfile(createIfMissing: false);
      if (profile?.isSuperAdmin == true) {
        AppCreatorUnlock.unlockWithVerifiedPassword('super_admin');
        if (context.mounted) {
          await _openCreatorDashboard(context);
        }
        return;
      }
    } catch (_) {}
  }

  final strings = AppLocale.instance.s;
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  var verifying = false;

  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> submit() async {
            if (!(formKey.currentState?.validate() ?? false) || verifying) return;
            if (!SupabaseBootstrap.isReady) {
              await showBakeryUpdateBanner(sheetCtx, title: strings.managerShareStoreSupabaseSnack);
              return;
            }
            setSheetState(() => verifying = true);
            try {
              await SaasRepository.instance.fetchAllBusinessesForCreator(controller.text.trim());
              AppCreatorUnlock.unlockWithVerifiedPassword(controller.text);
              if (sheetCtx.mounted) Navigator.pop(sheetCtx, true);
            } catch (_) {
              if (sheetCtx.mounted) {
                await showBakeryNoticeBanner(
                  sheetCtx,
                  title: strings.appCreatorWrongPassword,
                  isError: true,
                );
              }
            } finally {
              if (sheetCtx.mounted) setSheetState(() => verifying = false);
            }
          }

          return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: BakeryTheme.accent(sheetCtx).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: BakeryTheme.border(sheetCtx)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings_outlined, color: BakeryTheme.accent(sheetCtx)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            strings.appCreatorBannerTitle,
                            style: BakeryTheme.text(sheetCtx, fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    strings.appCreatorBannerSub,
                    style: BakeryTheme.subtitleText(sheetCtx, fontSize: 14, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: controller,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    decoration: bakeryInputDecoration(
                      sheetCtx,
                      label: strings.appCreatorPasswordLabel,
                      icon: Icons.lock_outline_rounded,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return strings.enterPassword;
                      return null;
                    },
                    onFieldSubmitted: (_) => submit(),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: verifying ? null : submit,
                    child: verifying
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(strings.appCreatorEnter),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetCtx, false),
                    child: Text(strings.cancel),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
        },
      );
    },
  );

  controller.dispose();
  if (ok != true || !context.mounted) return;
  await _openCreatorDashboard(context);
}

Future<void> _openCreatorDashboard(BuildContext context) async {
  if (!SupabaseBootstrap.isReady) {
    await showBakeryUpdateBanner(context, title: AppLocale.instance.s.managerShareStoreSupabaseSnack);
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const AppCreatorDashboardScreen()),
  );
}
