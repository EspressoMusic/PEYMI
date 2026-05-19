import 'package:flutter/material.dart';

import '../core/app_theme_mode.dart';
import '../core/manager_store.dart';
import 'customer_appointment_tab.dart';

/// Stable home tab body: catalog or appointments (avoids widget-type swap crashes).
class HomeCatalogSlot extends StatefulWidget {
  const HomeCatalogSlot({
    super.key,
    required this.catalogPage,
    required this.needLinkMessage,
  });

  final Widget catalogPage;
  final String needLinkMessage;

  @override
  State<HomeCatalogSlot> createState() => _HomeCatalogSlotState();
}

class _HomeCatalogSlotState extends State<HomeCatalogSlot> {
  @override
  void initState() {
    super.initState();
    ManagerStore.instance.addListener(_rebuild);
    _ensureDemoIfNeeded();
  }

  Future<void> _ensureDemoIfNeeded() async {
    if (!ManagerStore.instance.isAppointmentCustomerMode) return;
    if (ManagerStore.instance.hasLinkedBusiness) return;
    final ok = await ManagerStore.instance.ensureDemoStoreLinked(preferAppointments: true);
    if (ok && mounted) setState(() {});
  }

  @override
  void dispose() {
    ManagerStore.instance.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final mgr = ManagerStore.instance;
    final showAppointments = mgr.isAppointmentCustomerMode;
    final slug = mgr.linkedBusinessSlug ?? '';

    return IndexedStack(
      index: showAppointments ? 1 : 0,
      sizing: StackFit.expand,
      children: [
        KeyedSubtree(
          key: const ValueKey('home_catalog_products'),
          child: widget.catalogPage,
        ),
        KeyedSubtree(
          key: const ValueKey('home_catalog_appointments'),
          child: slug.isNotEmpty
              ? SafeArea(
                  bottom: false,
                  minimum: const EdgeInsets.only(top: 20),
                  child: CustomerAppointmentTab(slug: slug, embedded: true),
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      widget.needLinkMessage,
                      textAlign: TextAlign.center,
                      style: BakeryTheme.text(context, fontSize: 16),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
