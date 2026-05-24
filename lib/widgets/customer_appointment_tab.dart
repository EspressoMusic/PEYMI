import 'package:flutter/material.dart';

import '../core/app_locale.dart';
import '../core/demo_store.dart';
import '../core/manager_store.dart';
import '../core/supabase/supabase_bootstrap.dart';
import '../saas/data/saas_repository.dart';
import '../saas/models/saas_models.dart';
import '../saas/screens/public_appointment_screen.dart';
import '../saas/utils/appointment_strings.dart';

/// In-app customer tab: weekly appointment booking (replaces catalog when enabled).
class CustomerAppointmentTab extends StatefulWidget {
  const CustomerAppointmentTab({
    super.key,
    required this.slug,
    this.embedded = false,
  });

  final String slug;
  final bool embedded;

  @override
  State<CustomerAppointmentTab> createState() => _CustomerAppointmentTabState();
}

class _CustomerAppointmentTabState extends State<CustomerAppointmentTab> {
  SaasBusiness? _business;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CustomerAppointmentTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug) _load();
  }

  Future<void> _load() async {
    if (ManagerStore.instance.isAppointmentCustomerMode) {
      await ManagerStore.instance.ensureAppointmentModeReady();
      if (!ManagerStore.instance.hasLinkedBusiness) {
        await ManagerStore.instance.ensureDemoStoreLinked(preferAppointments: true);
      }
    }
    if (!SupabaseBootstrap.isReady) {
      setState(() {
        _error = 'Server not configured';
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final business = await SaasRepository.instance.fetchBusinessBySlug(widget.slug);
      if (!mounted) return;
      if (business == null) {
        setState(() {
          _error = 'Store not found';
          _loading = false;
        });
        return;
      }
      final panelMode = ManagerStore.instance.isAppointmentCustomerMode
          ? 'appointments'
          : business.storeMode;
      await ManagerStore.instance.linkOnlineBusiness(
        id: business.id,
        slug: business.slug,
        storeMode: panelMode,
      );
      setState(() {
        _business = business;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppointmentStrings.friendlyError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _loading ? 0 : (_error != null ? 1 : 2),
      sizing: StackFit.expand,
      children: [
        const Center(child: CircularProgressIndicator()),
        Center(child: Text(_error ?? '')),
        _business == null
            ? const SizedBox.shrink()
            : _AppointmentBody(
                slug: widget.slug,
                business: _business!,
                embedded: widget.embedded,
              ),
      ],
    );
  }
}

class _AppointmentBody extends StatelessWidget {
  const _AppointmentBody({
    required this.slug,
    required this.business,
    required this.embedded,
  });

  final String slug;
  final SaasBusiness business;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final calendar = PublicAppointmentScreen(
      key: ValueKey('appt-body-${business.id}'),
      business: business,
      embedded: embedded,
    );
    if (!DemoStore.isDemoSlug(slug)) return calendar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.amber.shade100,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              AppLocale.instance.s.demoStoreBanner(slug),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ),
        Expanded(child: calendar),
      ],
    );
  }
}
