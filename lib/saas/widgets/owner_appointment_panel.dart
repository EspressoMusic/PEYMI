import 'package:flutter/material.dart';

import '../../core/app_theme_mode.dart';
import '../data/saas_repository.dart';
import '../models/appointment_models.dart';
import '../models/saas_models.dart';

class OwnerAppointmentPanel extends StatefulWidget {
  const OwnerAppointmentPanel({super.key, required this.business});

  final SaasBusiness business;

  @override
  State<OwnerAppointmentPanel> createState() => _OwnerAppointmentPanelState();
}

class _OwnerAppointmentPanelState extends State<OwnerAppointmentPanel> {
  List<SaasAppointment> _appointments = [];
  List<AppointmentWaitlistEntry> _waitlist = [];
  BusinessAppointmentSettings? _settings;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final appointments = await SaasRepository.instance.fetchBusinessAppointments(
      businessId: widget.business.id,
      from: now.subtract(const Duration(days: 1)),
      to: now.add(const Duration(days: 30)),
    );
    final waitlist = await SaasRepository.instance.fetchWaitlist(widget.business.id);
    final settings = await SaasRepository.instance.fetchAppointmentSettings(widget.business.id);
    if (!mounted) return;
    setState(() {
      _appointments = appointments;
      _waitlist = waitlist;
      _settings = settings;
      _loading = false;
    });
  }

  List<SaasAppointment> get _todayAppts {
    final t = DateTime.now();
    return _appointments.where((a) {
      return a.appointmentDate.year == t.year &&
          a.appointmentDate.month == t.month &&
          a.appointmentDate.day == t.day &&
          a.status != 'cancelled';
    }).toList();
  }

  int get _weekBooked => _appointments
      .where((a) => a.status != 'cancelled')
      .length;

  int get _cancelledCount => _appointments.where((a) => a.status == 'cancelled').length;

  Future<void> _cancel(SaasAppointment a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: Text('${a.customerName} · ${a.appointmentTime}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel appointment')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await SaasRepository.instance.cancelAppointment(a.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment cancelled')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _setStatus(SaasAppointment a, String status) async {
    try {
      await SaasRepository.instance.updateAppointmentStatus(
        appointmentId: a.id,
        status: status,
      );
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _editSettings() async {
    final durationCtrl = TextEditingController(
      text: '${_settings?.slotDurationMinutes ?? 30}',
    );
    final noticeCtrl = TextEditingController(
      text: '${_settings?.bookingNoticeMinutes ?? 60}',
    );
    final aheadCtrl = TextEditingController(text: '${_settings?.maxDaysAhead ?? 30}');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Appointment settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: durationCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Slot duration (minutes)'),
            ),
            TextField(
              controller: noticeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Booking notice (minutes)'),
            ),
            TextField(
              controller: aheadCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Max days ahead'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Default hours: Sun–Thu 09:00–17:00 (contact support to customize days).',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );

    if (ok != true) return;
    await SaasRepository.instance.updateAppointmentSettings(
      businessId: widget.business.id,
      slotDurationMinutes: int.tryParse(durationCtrl.text),
      bookingNoticeMinutes: int.tryParse(noticeCtrl.text),
      maxDaysAhead: int.tryParse(aheadCtrl.text),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final upcoming = _appointments
        .where((a) => a.status != 'cancelled' && a.status != 'completed')
        .toList()
      ..sort((a, b) {
        final ad = a.appointmentDate.compareTo(b.appointmentDate);
        if (ad != 0) return ad;
        return a.appointmentTime.compareTo(b.appointmentTime);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _statChip('Today', '${_todayAppts.length}'),
            _statChip('Booked this week', '$_weekBooked'),
            _statChip('Cancelled', '$_cancelledCount'),
            _statChip('Waitlist', '${_waitlist.where((w) => w.notifyStatus == 'waiting').length}'),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _editSettings,
          icon: const Icon(Icons.settings),
          label: const Text('Appointment settings'),
        ),
        const SizedBox(height: 16),
        Text('Today appointments', style: BakeryTheme.text(context, fontSize: 17, fontWeight: FontWeight.w800)),
        if (_todayAppts.isEmpty)
          Text('None today', style: BakeryTheme.subtitleText(context))
        else
          ..._todayAppts.map((a) => _appointmentTile(a)),
        const SizedBox(height: 16),
        Text('Upcoming', style: BakeryTheme.text(context, fontSize: 17, fontWeight: FontWeight.w800)),
        if (upcoming.isEmpty)
          Text('No upcoming appointments', style: BakeryTheme.subtitleText(context))
        else
          ...upcoming.take(20).map((a) => _appointmentTile(a)),
        const SizedBox(height: 16),
        Text('Waitlist (notified when slot opens)', style: BakeryTheme.text(context, fontSize: 17, fontWeight: FontWeight.w800)),
        if (_waitlist.isEmpty)
          Text('No waitlist entries', style: BakeryTheme.subtitleText(context))
        else
          ..._waitlist.take(15).map(
                (w) => ListTile(
                  dense: true,
                  title: Text('${w.customerName} · ${w.appointmentTime}'),
                  subtitle: Text('${_date(w.appointmentDate)} · ${w.notifyStatus}'),
                ),
              ),
      ],
    );
  }

  Widget _statChip(String label, String value) {
    return Chip(
      label: Text('$label: $value', style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  Widget _appointmentTile(SaasAppointment a) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('${a.customerName} · ${a.appointmentTime}'),
        subtitle: Text('${_date(a.appointmentDate)} · ${a.status} · ${a.customerPhone ?? ''}'),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'cancel') {
              _cancel(a);
            } else {
              _setStatus(a, v);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'completed', child: Text('Mark completed')),
            PopupMenuItem(value: 'no_show', child: Text('Mark no-show')),
            PopupMenuItem(value: 'confirmed', child: Text('Mark confirmed')),
            PopupMenuItem(value: 'cancel', child: Text('Cancel appointment')),
          ],
        ),
      ),
    );
  }

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
