import 'package:flutter/material.dart';

import '../core/app_locale.dart';
import '../core/app_theme_mode.dart';
import '../core/bakery_square_palette.dart';
import '../core/customer_appointments_store.dart';
import '../core/supabase/supabase_bootstrap.dart';
import '../saas/data/saas_repository.dart';
import '../saas/models/appointment_models.dart';
import '../saas/models/saas_models.dart';
import '../saas/utils/appointment_strings.dart';
import 'customer_tab_body.dart';

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
        _error = AppointmentStrings.friendlyError(e);
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
        content: Text('${_fmt(ap)}\n${ap.serviceName}'),
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
    final canCancel = ap.status != 'cancelled' && ap.status != 'completed';

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _detailRow(ctx, AppointmentStrings.isHebrew ? 'תאריך' : 'Date', _fmt(ap)),
              _detailRow(ctx, AppointmentStrings.yourName.replaceAll(' *', ''), ap.customerName),
              if (ap.customerPhone != null)
                _detailRow(ctx, AppointmentStrings.phone.replaceAll(' *', ''), ap.customerPhone!),
              _detailRow(ctx, AppointmentStrings.isHebrew ? 'שירות' : 'Service', ap.serviceName),
              _detailRow(ctx, AppointmentStrings.isHebrew ? 'סטטוס' : 'Status', _statusLabel(ap.status)),
              if (ap.notes != null && ap.notes!.trim().isNotEmpty)
                _detailRow(
                  ctx,
                  AppointmentStrings.notesOptional
                      .replaceAll(' (אופציונלי)', '')
                      .replaceAll(' (optional)', ''),
                  ap.notes!,
                ),
              const SizedBox(height: 20),
              if (canCancel)
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _cancel(ap);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(AppointmentStrings.isHebrew ? 'בטל תור' : 'Cancel appointment'),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppointmentStrings.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: BakeryTheme.subtitleText(context, fontSize: 14)),
          ),
          Expanded(
            child: Text(
              value,
              style: BakeryTheme.text(context, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(SaasAppointment ap) =>
      '${ap.appointmentDate.day.toString().padLeft(2, '0')}/${ap.appointmentDate.month.toString().padLeft(2, '0')}/${ap.appointmentDate.year} · ${ap.appointmentTime}';

  static String _shortDate(SaasAppointment ap) =>
      '${ap.appointmentDate.day.toString().padLeft(2, '0')}/${ap.appointmentDate.month.toString().padLeft(2, '0')}';

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
      return const CustomerTabBody(child: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return CustomerTabBody(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    if (list.isEmpty) {
      return CustomerTabBody(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              strings.customerNoAppointments,
              textAlign: TextAlign.center,
              style: BakeryTheme.text(context, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return CustomerTabBody(
      child: RefreshIndicator(
        onRefresh: _load,
        child: GridView.builder(
          padding: CustomerTabBody.listPadding,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1,
          ),
          itemCount: list.length,
          itemBuilder: (_, i) => _AppointmentSquareTile(
            appointment: list[i],
            onTap: () => _showDetails(list[i]),
          ),
        ),
      ),
    );
  }
}

class _AppointmentSquareTile extends StatelessWidget {
  const _AppointmentSquareTile({
    required this.appointment,
    required this.onTap,
  });

  final SaasAppointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cancelled = appointment.status == 'cancelled';
    final surface = BakeryTheme.appointmentTileSurface(context);

    return BakerySquarePalette.shell(
      context: context,
      borderRadius: 18,
      color: surface,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_available_outlined,
                size: 32,
                color: cancelled
                    ? BakeryTheme.muted(context)
                    : BakeryTheme.accent(context),
              ),
              const SizedBox(height: 8),
              Text(
                _CustomerAppointmentHistoryTabState._shortDate(appointment),
                style: BakeryTheme.text(
                  context,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ).copyWith(
                  decoration: cancelled ? TextDecoration.lineThrough : null,
                  color: cancelled ? BakeryTheme.muted(context) : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                appointment.appointmentTime,
                style: BakeryTheme.text(
                  context,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ).copyWith(
                  decoration: cancelled ? TextDecoration.lineThrough : null,
                  color: cancelled ? BakeryTheme.muted(context) : null,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _CustomerAppointmentHistoryTabState._statusLabel(appointment.status),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BakeryTheme.subtitleText(context, fontSize: 12),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
