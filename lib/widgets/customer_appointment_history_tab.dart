import 'package:flutter/material.dart';

import '../core/app_locale.dart';
import '../core/app_theme_mode.dart';
import '../core/customer_appointments_store.dart';
import '../core/supabase/supabase_bootstrap.dart';
import '../saas/data/saas_repository.dart';
import '../saas/models/appointment_models.dart';
import '../saas/models/saas_models.dart';
import '../saas/utils/appointment_strings.dart';

/// Customer tab: past and upcoming appointments — view details and cancel.
class CustomerAppointmentHistoryTab extends StatefulWidget {
  const CustomerAppointmentHistoryTab({super.key, required this.businessSlug});

  final String businessSlug;

  @override
  State<CustomerAppointmentHistoryTab> createState() => _CustomerAppointmentHistoryTabState();
}

class _CustomerAppointmentHistoryTabState extends State<CustomerAppointmentHistoryTab> {
  SaasBusiness? _business;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    CustomerAppointmentsStore.instance.addListener(_onStore);
    _load();
  }

  @override
  void dispose() {
    CustomerAppointmentsStore.instance.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    if (!SupabaseBootstrap.isReady) {
      setState(() {
        _error = AppointmentStrings.unavailable;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final business = await SaasRepository.instance.fetchBusinessBySlug(widget.businessSlug);
      if (!mounted) return;
      if (business == null) {
        setState(() {
          _error = AppointmentStrings.isHebrew ? 'חנות לא נמצאה' : 'Store not found';
          _loading = false;
        });
        return;
      }
      _business = business;
      final phone = CustomerAppointmentsStore.instance.savedPhone;
      if (phone != null && phone.isNotEmpty) {
        final remote = await SaasRepository.instance.fetchCustomerAppointments(
          businessId: business.id,
          customerPhone: phone,
        );
        await CustomerAppointmentsStore.instance.upsertFromServer(remote);
      }
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<SaasAppointment> get _forBusiness {
    final id = _business?.id;
    if (id == null) return const [];
    return CustomerAppointmentsStore.instance.records
        .where((a) => a.businessId == id)
        .toList();
  }

  Future<void> _cancel(SaasAppointment ap) async {
    final phone = CustomerAppointmentsStore.instance.savedPhone ?? ap.customerPhone;
    if (phone == null || phone.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppointmentStrings.isHebrew ? 'ביטול תור?' : 'Cancel appointment?'),
        content: Text(
          '${_fmt(ap)}\n${ap.serviceName}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppointmentStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppointmentStrings.isHebrew ? 'בטל תור' : 'Cancel'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await SaasRepository.instance.cancelAppointment(ap.id, customerPhone: phone);
      await CustomerAppointmentsStore.instance.markCancelled(ap.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppointmentStrings.isHebrew ? 'התור בוטל' : 'Appointment cancelled',
            ),
          ),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  void _showDetails(SaasAppointment ap) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppointmentStrings.isHebrew ? 'פרטי תור' : 'Appointment details',
              style: BakeryTheme.text(ctx, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _detailRow(ctx, AppointmentStrings.isHebrew ? 'תאריך' : 'Date', _fmt(ap)),
            _detailRow(ctx, AppointmentStrings.yourName.replaceAll(' *', ''), ap.customerName),
            if (ap.customerPhone != null)
              _detailRow(ctx, AppointmentStrings.phone.replaceAll(' *', ''), ap.customerPhone!),
            _detailRow(ctx, AppointmentStrings.isHebrew ? 'שירות' : 'Service', ap.serviceName),
            _detailRow(ctx, AppointmentStrings.isHebrew ? 'סטטוס' : 'Status', _statusLabel(ap.status)),
            if (ap.notes != null && ap.notes!.trim().isNotEmpty)
              _detailRow(ctx, AppointmentStrings.notesOptional.replaceAll(' (אופציונלי)', '').replaceAll(' (optional)', ''), ap.notes!),
            if (ap.status != 'cancelled' && ap.status != 'completed') ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _cancel(ap);
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                child: Text(AppointmentStrings.isHebrew ? 'בטל תור' : 'Cancel appointment'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: BakeryTheme.subtitleText(context)),
          ),
          Expanded(child: Text(value, style: BakeryTheme.text(context, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  static String _fmt(SaasAppointment ap) =>
      '${ap.appointmentDate.day.toString().padLeft(2, '0')}/${ap.appointmentDate.month.toString().padLeft(2, '0')}/${ap.appointmentDate.year} · ${ap.appointmentTime}';

  static String _statusLabel(String status) {
    if (!AppointmentStrings.isHebrew) return status;
    switch (status) {
      case 'new':
        return 'חדש';
      case 'confirmed':
        return 'מאושר';
      case 'cancelled':
        return 'בוטל';
      case 'completed':
        return 'הושלם';
      case 'no_show':
        return 'לא הגיע';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocale.instance.s;
    final list = _forBusiness;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            strings.customerNoAppointments,
            textAlign: TextAlign.center,
            style: BakeryTheme.text(context, fontSize: 16),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final ap = list[i];
          final cancelled = ap.status == 'cancelled';
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              onTap: () => _showDetails(ap),
              title: Text(
                _fmt(ap),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  decoration: cancelled ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text('${ap.serviceName} · ${_statusLabel(ap.status)}'),
              trailing: const Icon(Icons.chevron_left),
            ),
          );
        },
      ),
    );
  }
}
