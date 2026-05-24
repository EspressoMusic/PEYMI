import 'package:flutter/material.dart';

import '../core/manager_store.dart';
import 'customer_appointment_history_tab.dart';

/// Swaps orders ↔ appointment history without widget-type crashes.
class HomeDealsSlot extends StatefulWidget {
  const HomeDealsSlot({super.key, required this.productDealsPage});

  final Widget productDealsPage;

  @override
  State<HomeDealsSlot> createState() => _HomeDealsSlotState();
}

class _HomeDealsSlotState extends State<HomeDealsSlot> {
  @override
  void initState() {
    super.initState();
    ManagerStore.instance.addListener(_rebuild);
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
    return KeyedSubtree(
      key: ValueKey(
        ManagerStore.instance.isAppointmentCustomerMode ? 'home_deals_appointment' : 'home_deals_products',
      ),
      child: widget.productDealsPage,
    );
  }
}

class HomeOrdersSlot extends StatefulWidget {
  const HomeOrdersSlot({super.key});

  @override
  State<HomeOrdersSlot> createState() => _HomeOrdersSlotState();
}

class _HomeOrdersSlotState extends State<HomeOrdersSlot> {
  @override
  void initState() {
    super.initState();
    ManagerStore.instance.addListener(_rebuild);
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
    final appointment = ManagerStore.instance.isAppointmentCustomerMode;
    final slug = ManagerStore.instance.linkedBusinessSlug ?? '';

    if (!appointment) {
      return const SizedBox.shrink(key: ValueKey('home_orders_products_placeholder'));
    }

    return KeyedSubtree(
      key: const ValueKey('home_orders_appointments'),
      child: slug.isNotEmpty
          ? CustomerAppointmentHistoryTab(businessSlug: slug)
          : const SizedBox.shrink(),
    );
  }
}
