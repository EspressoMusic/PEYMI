import 'dart:async';

import 'package:flutter/material.dart';



import '../../core/app_locale.dart';

import '../../core/app_theme_mode.dart';

import '../../core/bakery_navigator.dart';

import '../../core/manager_credentials_store.dart';

import '../../core/manager_store.dart';

import '../../core/policy_consent_store.dart';

import '../../core/supabase/supabase_bootstrap.dart';

import '../../widgets/bakery_celebration.dart';
import '../../widgets/bakery_orders_panel.dart';
import '../../widgets/legal_acceptance_checkbox.dart';

import '../data/saas_repository.dart';

import '../models/saas_models.dart';

import 'owner_dashboard_screen.dart';
import 'phone_verification_screen.dart';
import '../widgets/super_admin_gate.dart';



class CreateStoreScreen extends StatefulWidget {

  const CreateStoreScreen({super.key});



  @override

  State<CreateStoreScreen> createState() => _CreateStoreScreenState();

}



class _CreateStoreScreenState extends State<CreateStoreScreen> {

  final _name = TextEditingController();

  final _managerPin = TextEditingController();

  final _contactEmail = TextEditingController();

  final _description = TextEditingController();

  final _phone = TextEditingController();

  final _address = TextEditingController();

  final _businessType = TextEditingController();

  var _loading = false;

  var _legalAccepted = false;


  var _checkingLegal = true;

  var _additionalDetailsExpanded = false;

  var _gateChecking = true;

  var _gateReady = false;

  String? _error;



  AppStrings get strings => AppLocale.instance.s;



  @override

  void initState() {

    super.initState();

    _loadLegalState();

    _prefillOwnerEmail();

    WidgetsBinding.instance.addPostFrameCallback((_) => _runAccessGate());

  }



  Future<void> _runAccessGate() async {

    final repo = SaasRepository.instance;

    var profile = await repo.fetchCurrentProfile();

    if (!mounted) return;



    if (profile == null) {

      final signedIn = repo.currentUser != null;

      final msg = signedIn

          ? 'Could not load your profile. Sign out, sign in again with shilohdhd1@gmail.com, then retry.'

          : 'Please sign in first (Settings → Create Store).';

      unawaited(showBakeryNoticeBanner(context, title: msg, isError: true));

      if (mounted) popRouteSafely(context);

      return;

    }



    if (!profile.phoneVerified) {

      final verified = await pushRouteSafely<bool>(

        MaterialPageRoute(builder: (_) => const PhoneVerificationScreen()),

      );

      if (!mounted) return;

      if (verified != true) {

        popRouteSafely(context);

        return;

      }

      profile = await repo.fetchCurrentProfile(forceRefresh: true);

      if (!mounted) return;

    }



    if (profile?.isSuperAdmin == true) {

      final goAdmin = await showOverlaySafely<bool>(

        context: context,

        show: (host) => showDialog<bool>(

          context: host,

          useRootNavigator: true,

          builder: (ctx) => AlertDialog(

            title: const Text('Super Admin'),

            content: const Text('Open Super Admin dashboard or continue creating a store?'),

            actions: [

              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Super Admin')),

              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Create Store')),

            ],

          ),

        ),

      );

      if (!mounted) return;

      if (goAdmin == true) {

        await pushRouteSafely(

          MaterialPageRoute(builder: (_) => const SuperAdminGate()),

        );

        if (mounted) popRouteSafely(context);

        return;

      }

    }



    if (!mounted) return;

    setState(() {

      _gateChecking = false;

      _gateReady = true;

    });

  }



  void _prefillOwnerEmail() {

    if (!SupabaseBootstrap.isReady) return;

    final email = SaasRepository.instance.currentUser?.email?.trim();

    if (email != null && email.isNotEmpty && _contactEmail.text.isEmpty) {

      _contactEmail.text = email;

    }

  }



  Future<void> _loadLegalState() async {

    try {

      final ok = await SaasRepository.instance.hasAcceptedCurrentLegal();

      if (!mounted) return;

      setState(() {

        _legalAccepted = ok;

        _checkingLegal = false;

      });

    } catch (_) {

      if (!mounted) return;

      setState(() => _checkingLegal = false);

    }

  }



  @override

  void dispose() {

    _name.dispose();

    _managerPin.dispose();

    _contactEmail.dispose();

    _description.dispose();

    _phone.dispose();

    _address.dispose();

    _businessType.dispose();

    super.dispose();

  }



  Future<void> _submit() async {

    if (!_gateReady || _gateChecking) return;

    if (_name.text.trim().isEmpty) {

      setState(() => _error = strings.storeNameRequired);

      return;

    }

    final pin = _managerPin.text.trim();

    if (pin.length < 4) {

      setState(() => _error = strings.managerPinTooShort);

      return;

    }

    if (!_legalAccepted) {

      setState(() {

        _error = strings.legalMustAccept;

        _additionalDetailsExpanded = true;

      });

      return;

    }

    setState(() {

      _loading = true;

      _error = null;

    });

    try {

      await SaasRepository.instance.recordLegalAcceptance();

      await PolicyConsentStore.instance.accept(PolicyAudience.owner);

      final slug = await SaasRepository.instance.allocateSlugForBusinessName(_name.text.trim());

      final contactEmail = _contactEmail.text.trim();

      final result = await SaasRepository.instance.createBusinessViaEdge(

        businessName: _name.text.trim(),

        slug: slug,

        managerPin: pin,

        description: _description.text.trim().isEmpty ? null : _description.text.trim(),

        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),

        address: _address.text.trim().isEmpty ? null : _address.text.trim(),

        businessType: _businessType.text.trim().isEmpty ? null : _businessType.text.trim(),

        contactEmail: contactEmail.isEmpty ? null : contactEmail,

      );

      final businessJson = result['business'] as Map<String, dynamic>?;

      if (!mounted || businessJson == null) return;

      final business = SaasBusiness.fromJson(businessJson);

      await ManagerStore.instance.linkOnlineBusiness(

        id: business.id,

        slug: business.slug,

        storeMode: 'products',

        contactEmail: business.contactEmail,

      );

      await ManagerStore.instance.setCustomerPanelMode('products');

      await ManagerCredentialsStore.instance.save(

        slug: business.slug,

        pin: pin,

        remember: true,

      );

      if (!mounted) return;

      await pushReplacementRouteSafely(

        MaterialPageRoute(

          builder: (_) => OwnerDashboardScreen(

            business: business,

            justCreated: true,

          ),

        ),

      );

    } catch (e) {

      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));

    } finally {

      if (mounted) setState(() => _loading = false);

    }

  }



  @override

  Widget build(BuildContext context) {

    final accent = BakeryTheme.accent(context);



    return Scaffold(

      appBar: AppBar(title: const SizedBox.shrink()),

      body: ListView(

        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),

        children: [

          Text(

            strings.openStoreTitle,

            textAlign: TextAlign.center,

            style: BakeryTheme.text(context, fontSize: 24, fontWeight: FontWeight.w800),

          ),

          const SizedBox(height: 8),

          Text(

            strings.openStoreSubtitle,

            textAlign: TextAlign.center,

            style: BakeryTheme.subtitleText(context, fontSize: 14, height: 1.4),

          ),

          const SizedBox(height: 22),

          if (_gateChecking)

            const Padding(

              padding: EdgeInsets.symmetric(vertical: 24),

              child: Center(

                child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2)),

              ),

            )

          else ...[

          BakeryOrdersPanel(

            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [

                TextField(

                  controller: _name,

                  textInputAction: TextInputAction.next,

                  decoration: bakeryInputDecoration(

                    context,

                    label: strings.storeNameLabel,

                    icon: Icons.storefront_outlined,

                  ),

                ),

                const SizedBox(height: 16),

                TextField(

                  controller: _managerPin,

                  obscureText: true,

                  textInputAction: TextInputAction.done,

                  decoration: bakeryInputDecoration(

                    context,

                    label: strings.managerPinChooseLabel,

                    icon: Icons.lock_outline,

                  ),

                ),

                const SizedBox(height: 8),

                Text(

                  strings.managerPinChooseHint,

                  style: BakeryTheme.subtitleText(context, fontSize: 12, height: 1.35),

                ),

              ],

            ),

          ),

          const SizedBox(height: 14),

          BakeryOrdersPanel(

            padding: EdgeInsets.zero,

            child: Theme(

              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),

              child: ExpansionTile(

                key: ValueKey(_additionalDetailsExpanded),

                initiallyExpanded: _additionalDetailsExpanded,

                onExpansionChanged: (expanded) => setState(() => _additionalDetailsExpanded = expanded),

                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),

                childrenPadding: const EdgeInsets.fromLTRB(18, 12, 18, 18),

                clipBehavior: Clip.none,

                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22))),

                collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22))),

                iconColor: accent,

                collapsedIconColor: accent,

                title: Text(

                  strings.storeAdditionalDetails,

                  style: BakeryTheme.text(context, fontSize: 16, fontWeight: FontWeight.w800),

                ),

                children: [

                  TextField(

                    controller: _contactEmail,

                    keyboardType: TextInputType.emailAddress,

                    autocorrect: false,

                    decoration: bakeryInputDecoration(

                      context,

                      label: strings.storeContactEmailLabel,

                      icon: Icons.email_outlined,

                    ),

                  ),

                  const SizedBox(height: 14),

                  TextField(

                    controller: _description,

                    maxLines: 3,

                    decoration: bakeryInputDecoration(

                      context,

                      label: strings.storeDescriptionLabel,

                      icon: Icons.notes,

                    ),

                  ),

                  const SizedBox(height: 12),

                  TextField(

                    controller: _phone,

                    keyboardType: TextInputType.phone,

                    decoration: bakeryInputDecoration(

                      context,

                      label: strings.storePhoneLabel,

                      icon: Icons.phone_outlined,

                    ),

                  ),

                  const SizedBox(height: 12),

                  TextField(

                    controller: _address,

                    decoration: bakeryInputDecoration(

                      context,

                      label: strings.storeAddressLabel,

                      icon: Icons.place_outlined,

                    ),

                  ),

                  const SizedBox(height: 12),

                  TextField(

                    controller: _businessType,

                    decoration: bakeryInputDecoration(

                      context,

                      label: strings.storeBusinessTypeLabel,

                      icon: Icons.category_outlined,

                    ),

                  ),

                  const SizedBox(height: 16),

                  if (_checkingLegal)

                    const Padding(

                      padding: EdgeInsets.symmetric(vertical: 8),

                      child: Center(

                        child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),

                      ),

                    )

                  else

                    LegalAcceptanceCheckbox(

                      value: _legalAccepted,

                      onChanged: (v) {

                        if (_loading) return;

                        setState(() => _legalAccepted = v ?? false);

                      },

                    ),

                ],

              ),

            ),

          ),

          if (_error != null) ...[

            const SizedBox(height: 14),

            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),

          ],

          const SizedBox(height: 22),

          FilledButton.icon(

            onPressed: (_loading || !_gateReady) ? null : _submit,

            icon: _loading

                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))

                : const Icon(Icons.storefront_outlined),

            label: Text(_loading ? strings.openStoreSubmitting : strings.openStoreSubmit),

          ),

          ],

        ],

      ),

    );

  }

}


