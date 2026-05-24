import 'package:flutter/material.dart';

import '../core/app_locale.dart';
import '../core/app_theme_mode.dart';
import '../core/bakery_navigator.dart';
import '../core/keyboard_safe.dart';
import '../core/email_validation.dart';
import '../core/demo_store.dart';
import '../core/manager_credentials_store.dart';
import '../core/manager_store.dart';
import '../core/store_scoped_reload.dart';
import '../core/staff_auth_config.dart';
import '../core/supabase/supabase_bootstrap.dart';
import '../manager_ui.dart';
import '../widgets/bakery_celebration.dart';
import 'data/saas_repository.dart';
import 'saas_flow.dart';
import 'utils/slug_utils.dart';

/// Verifies manager panel password for a specific store slug.
Future<bool> verifyManagerPanelPassword({
  required String slug,
  required String password,
}) async {
  final pin = password.trim();
  final normalizedSlug = normalizeSlug(slug);
  if (pin.length < 4 || normalizedSlug.isEmpty) return false;

  if (DemoStore.isDemoSlug(normalizedSlug) && pin == DemoStore.managerPin) {
    return true;
  }

  if (SupabaseBootstrap.isReady) {
    try {
      final ok = await SaasRepository.instance.verifyBusinessManagerPin(
        slug: normalizedSlug,
        pin: pin,
      );
      if (ok) return true;
    } catch (_) {
      // Fall through to global PIN.
    }
  }

  final global = StaffAuthConfig.effectiveManagerPin;
  if (global.isNotEmpty && pin == global) return true;
  return false;
}

/// Supabase **owner account** password reset (create-store sign-in only).
Future<void> showOwnerAccountPasswordResetSheet(BuildContext context) async {
  await showBakeryDialog<void>(
    context: bakeryRootContext ?? context,
    panelPadding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
    child: const _OwnerAccountPasswordResetBody(),
  );
}

class _OwnerAccountPasswordResetBody extends StatefulWidget {
  const _OwnerAccountPasswordResetBody();

  @override
  State<_OwnerAccountPasswordResetBody> createState() => _OwnerAccountPasswordResetBodyState();
}

class _OwnerAccountPasswordResetBodyState extends State<_OwnerAccountPasswordResetBody> {
  final _emailController = TextEditingController();
  var _loading = false;
  var _closing = false;
  String? _error;
  String? _info;

  AppStrings get strings => AppLocale.instance.s;

  @override
  void deactivate() {
    _closing = true;
    super.deactivate();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted || _closing) return;
    setState(fn);
  }

  Future<void> _send() async {
    final email = _emailController.text.trim();
    if (!isValidEmailAddress(email)) {
      _safeSetState(() {
        _error = strings.managerResetInvalidEmail;
        _info = null;
      });
      return;
    }
    _safeSetState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      await SaasRepository.instance.resetPasswordForEmail(email);
      if (!mounted || _closing) return;
      _safeSetState(() => _info = strings.managerResetEmailSent);
    } catch (e) {
      if (!mounted || _closing) return;
      _safeSetState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (!mounted || _closing) return;
      _safeSetState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BakeryTheme.cardSurface(context).withValues(alpha: 0.95),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mark_email_read_outlined, size: 36, color: BakeryTheme.accent(context)),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          strings.managerForgotPasswordTitle,
          textAlign: TextAlign.center,
          style: BakeryTheme.text(context, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          strings.managerForgotPasswordHint,
          textAlign: TextAlign.center,
          style: BakeryTheme.subtitleText(context, fontSize: 13, height: 1.35),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          onChanged: (_) {
            if (_error != null || _info != null) {
              _safeSetState(() {
                _error = null;
                _info = null;
              });
            }
          },
          decoration: bakeryInputDecoration(context, label: 'Email', icon: Icons.email_outlined),
        ),
        if (_info != null) ...[
          const SizedBox(height: 10),
          Text(_info!, style: BakeryTheme.subtitleText(context, fontSize: 13, height: 1.35)),
        ],
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: Colors.red, height: 1.35)),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _loading ? null : _send,
          icon: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.email_outlined),
          label: Text(_loading ? strings.managerResetSending : strings.managerResetByEmail),
        ),
        TextButton(
          onPressed: _loading
              ? null
              : () {
                  _closing = true;
                  popRouteSafely(context);
                },
          child: Text(strings.cancel),
        ),
      ],
    );
  }
}

/// Change in-app manager panel PIN (store slug + owner account verification).
Future<void> showManagerPinChangeSheet(
  BuildContext context, {
  String? initialStoreSlug,
}) async {
  final strings = AppLocale.instance.s;
  final slugController = TextEditingController(text: initialStoreSlug ?? '');
  final ownerEmailController = TextEditingController();
  final ownerPasswordController = TextEditingController();
  final newPinController = TextEditingController();
  final confirmPinController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var loading = false;
  String? error;

  await showBakeryDialog<void>(
    context: bakeryRootContext ?? context,
    panelPadding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
    child: StatefulBuilder(
      builder: (ctx, setState) {
        Future<void> submit() async {
          if (!(formKey.currentState?.validate() ?? false) || loading) return;
          if (newPinController.text.trim() != confirmPinController.text.trim()) {
            setState(() => error = strings.managerPinMismatch);
            return;
          }
          setState(() {
            loading = true;
            error = null;
          });
          try {
            await SaasRepository.instance.changeManagerPinForOwnedStore(
              slug: slugController.text,
              ownerEmail: ownerEmailController.text,
              ownerPassword: ownerPasswordController.text,
              newPin: newPinController.text.trim(),
            );
            final slug = normalizeSlug(slugController.text);
            await linkManagerStoreBySlug(slug);
            await ManagerCredentialsStore.instance.save(
              slug: slug,
              pin: newPinController.text.trim(),
              remember: true,
            );
            if (!ctx.mounted) return;
            popRouteSafely(ctx);
            final host = bakeryRootContext ?? context;
            if (host.mounted) {
              await showBakerySuccessCelebration(
                host,
                title: strings.managerPinChangedTitle,
                subtitle: strings.managerPinChangedSub,
              );
            }
          } catch (e) {
            if (!ctx.mounted) return;
            final msg = e.toString().replaceFirst('Exception: ', '');
            setState(() {
              error = msg.contains('not the owner') || msg.contains('not found')
                  ? strings.managerChangePinNotOwner
                  : msg;
              loading = false;
            });
          }
        }

        return Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BakeryTheme.cardSurface(ctx).withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_reset_rounded, size: 36, color: BakeryTheme.accent(ctx)),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                strings.managerChangePinTitle,
                textAlign: TextAlign.center,
                style: BakeryTheme.text(ctx, fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                strings.managerChangePinHint,
                textAlign: TextAlign.center,
                style: BakeryTheme.subtitleText(ctx, fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: slugController,
                textDirection: TextDirection.ltr,
                autocorrect: false,
                decoration: bakeryInputDecoration(
                  ctx,
                  label: strings.managerStoreNameLabel,
                  icon: Icons.storefront_outlined,
                ),
                validator: (v) =>
                    normalizeSlug(v ?? '').isEmpty ? strings.managerStoreNameRequired : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: ownerEmailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: bakeryInputDecoration(
                  ctx,
                  label: strings.managerOwnerAccountEmail,
                  icon: Icons.email_outlined,
                ),
                validator: (v) =>
                    !isValidEmailAddress(v) ? strings.managerResetInvalidEmail : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: ownerPasswordController,
                obscureText: true,
                decoration: bakeryInputDecoration(
                  ctx,
                  label: strings.managerOwnerAccountPassword,
                  icon: Icons.lock_outline,
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? strings.enterPassword : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: newPinController,
                obscureText: true,
                decoration: bakeryInputDecoration(
                  ctx,
                  label: strings.managerPinChooseLabel,
                  icon: Icons.pin_outlined,
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 4) return strings.managerPinTooShort;
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: confirmPinController,
                obscureText: true,
                decoration: bakeryInputDecoration(
                  ctx,
                  label: strings.managerPinConfirmLabel,
                  icon: Icons.pin_outlined,
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 4) return strings.managerPinTooShort;
                  return null;
                },
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: Colors.red, height: 1.35)),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: loading ? null : submit,
                icon: loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_rounded),
                label: Text(strings.save),
              ),
              TextButton(
                onPressed: loading ? null : () => popRouteSafely(ctx),
                child: Text(strings.cancel),
              ),
            ],
          ),
        );
      },
    ),
  );

  slugController.dispose();
  ownerEmailController.dispose();
  ownerPasswordController.dispose();
  newPinController.dispose();
  confirmPinController.dispose();
}

enum ManagerLoginDialogResult { approved, cancelled }

/// Manager login with remember-password and email recovery.
Future<ManagerLoginDialogResult> showManagerStoreLoginDialog(BuildContext context) async {
  final strings = AppLocale.instance.s;
  final slugController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var authFailed = false;
  var storeNotFound = false;
  var rememberPassword = false;
  var verifying = false;

  final saved = await ManagerCredentialsStore.instance.load();
  final linkedSlug = ManagerStore.instance.linkedBusinessSlug?.trim().toLowerCase();
  if (saved != null) {
    slugController.text = saved.slug;
    passwordController.text = saved.pin;
    rememberPassword = true;
  } else if (linkedSlug != null && linkedSlug.isNotEmpty) {
    slugController.text = linkedSlug;
  } else {
    slugController.text = DemoStore.slug;
  }

  final dialogHost = bakeryRootContext ?? context;
  if (!dialogHost.mounted) return ManagerLoginDialogResult.cancelled;

  Future<void> tryLogin(BuildContext dialogContext, StateSetter setDialogState) async {
    if (!(formKey.currentState?.validate() ?? false) || verifying) return;
    setDialogState(() {
      authFailed = false;
      storeNotFound = false;
      verifying = true;
    });

    final slug = normalizeSlug(slugController.text);
    final pin = passwordController.text.trim();
    final ok = await verifyManagerPanelPassword(slug: slug, password: pin);
    if (!dialogContext.mounted) return;

    if (!ok) {
      setDialogState(() {
        authFailed = true;
        verifying = false;
      });
      await showBakeryNoticeBanner(
        dialogContext,
        title: strings.wrongPassword,
        isError: true,
      );
      return;
    }

    final linked = DemoStore.isDemoSlug(slug)
        ? await linkDemoStoreForLogin()
        : await linkManagerStoreBySlug(slug);
    if (!dialogContext.mounted) return;
    if (!linked) {
      setDialogState(() {
        storeNotFound = true;
        verifying = false;
      });
      return;
    }

    await ManagerCredentialsStore.instance.save(
      slug: DemoStore.isDemoSlug(slug) ? DemoStore.slug : slug,
      pin: pin,
      remember: rememberPassword,
    );

    FocusManager.instance.primaryFocus?.unfocus();
    setDialogState(() => verifying = false);
    if (dialogContext.mounted) {
      Navigator.of(dialogContext, rootNavigator: true).pop(ManagerLoginDialogResult.approved);
    }
  }

  final result = await showBakeryDialog<ManagerLoginDialogResult>(
    context: dialogHost,
    showCloseButton: true,
    barrierDismissible: true,
    panelPadding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
    child: StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        return Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: BakeryTheme.cardSurface(dialogContext).withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(Icons.admin_panel_settings, size: 40, color: BakeryTheme.accent(dialogContext)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.managerLoginTitle,
                  textAlign: TextAlign.center,
                  style: BakeryTheme.text(dialogContext, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: slugController,
                  textInputAction: TextInputAction.next,
                  textDirection: TextDirection.ltr,
                  autocorrect: false,
                  decoration: bakeryInputDecoration(
                    dialogContext,
                    label: strings.managerStoreNameLabel,
                    icon: Icons.storefront_outlined,
                  ).copyWith(
                    fillColor: BakeryTheme.cardSurface(dialogContext).withValues(alpha: 0.95),
                  ),
                  validator: (value) {
                    if (value == null || normalizeSlug(value).isEmpty) {
                      return strings.managerStoreNameRequired;
                    }
                    return null;
                  },
                  onChanged: (_) {
                    if (storeNotFound) setDialogState(() => storeNotFound = false);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: BakeryTheme.body(dialogContext),
                  ),
                  decoration: bakeryInputDecoration(
                    dialogContext,
                    label: strings.passwordLabel,
                    icon: Icons.lock_outline,
                  ).copyWith(
                    fillColor: BakeryTheme.cardSurface(dialogContext).withValues(alpha: 0.95),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return strings.enterPassword;
                    if (value.trim().length < 4) return strings.managerPinTooShort;
                    return null;
                  },
                  onChanged: (_) {
                    if (authFailed) setDialogState(() => authFailed = false);
                  },
                  onFieldSubmitted: (_) => tryLogin(dialogContext, setDialogState),
                ),
                if (storeNotFound) ...[
                  const SizedBox(height: 8),
                  Text(
                    strings.managerLoginExistingNotFound,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
                  ),
                ],
                CheckboxListTile(
                  value: rememberPassword,
                  onChanged: (v) => setDialogState(() => rememberPassword = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    strings.managerRememberPassword,
                    style: BakeryTheme.subtitleText(dialogContext, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: verifying ? null : () => tryLogin(dialogContext, setDialogState),
                  icon: verifying
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.login_rounded),
                  label: Text(strings.login),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: verifying
                      ? null
                      : () => popThen(dialogContext, () async {
                          final host = bakeryRootContext ?? dialogHost;
                          if (!host.mounted) return;
                          if (!SupabaseBootstrap.isReady) {
                            await showBakeryNoticeBanner(
                              host,
                              title: strings.managerLoginNotConfigured,
                              isError: true,
                            );
                            return;
                          }
                          await showManagerPinChangeSheet(
                            host,
                            initialStoreSlug: slugController.text.trim(),
                          );
                        }),
                  icon: const Icon(Icons.lock_outline),
                  label: Text(strings.managerForgotPassword),
                ),
              ],
            ),
          );
      },
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    slugController.dispose();
    passwordController.dispose();
  });
  return result ?? ManagerLoginDialogResult.cancelled;
}

Future<void> runManagerLoginFromSettings(BuildContext context) async {
  final canUseStorePin = SupabaseBootstrap.isReady;
  if (!canUseStorePin && !StaffAuthConfig.isManagerLoginEnabled) {
    if (!context.mounted) return;
    await showBakeryNoticeBanner(
      context,
      title: AppLocale.instance.s.managerLoginNotConfigured,
      isError: true,
    );
    return;
  }

  final loginResult = await showManagerStoreLoginDialog(context);
  if (loginResult != ManagerLoginDialogResult.approved) return;

  final root = bakeryRootContext ?? context;
  if (!root.mounted) return;
  if (!ManagerStore.instance.hasLinkedBusiness) {
    await showBakeryNoticeBanner(
      root,
      title: AppLocale.instance.s.managerLoginExistingNotFound,
      isError: true,
    );
    return;
  }

  await ManagerStore.instance.ensureDemoCatalogReady();
  await reloadStoreScopedData();

  final navigator = bakeryNavigatorKey.currentState;
  if (navigator == null) return;
  await waitForNavigatorSettle();
  await pushRouteSafely<void>(
    MaterialPageRoute<void>(builder: (_) => const ManagerHomePage()),
  );
}
