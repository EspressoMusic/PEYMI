import 'package:flutter/material.dart';

import '../../core/app_theme_mode.dart';
import '../../core/customer_appointments_store.dart';
import '../data/saas_repository.dart';
import '../models/appointment_models.dart';
import '../models/saas_models.dart';
import '../utils/appointment_strings.dart';
import '../widgets/customer_payment_instructions.dart';

/// Customer booking form after choosing a day and time.
class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({
    super.key,
    required this.business,
    required this.date,
    required this.time,
  });

  final SaasBusiness business;
  final DateTime date;
  final String time;

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final appointmentId = await SaasRepository.instance.bookAppointmentViaRpc(
        businessId: widget.business.id,
        date: widget.date,
        timeHHmm: widget.time,
        customerName: _nameCtrl.text.trim(),
        customerPhone: _phoneCtrl.text.trim(),
        customerEmail: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      final phone = _phoneCtrl.text.trim();
      await CustomerAppointmentsStore.instance.addBooking(
        customerPhone: phone,
        appointment: SaasAppointment(
          id: appointmentId,
          businessId: widget.business.id,
          customerName: _nameCtrl.text.trim(),
          customerPhone: phone,
          customerEmail: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          serviceName: AppointmentStrings.isHebrew ? 'תור' : 'Appointment',
          appointmentDate: widget.date,
          appointmentTime: widget.time,
          status: 'new',
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        ),
      );
      if (!mounted) return;
      await showCustomerPaymentSuccessDialog(
        context: context,
        businessId: widget.business.id,
        isAppointment: true,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${widget.date.day}/${widget.date.month}/${widget.date.year} · ${widget.time}';

    return Scaffold(
      appBar: AppBar(title: const SizedBox.shrink()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.business.businessName,
                    style: BakeryTheme.text(context, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(dateLabel, style: BakeryTheme.text(context, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    AppointmentStrings.pickDayAndTime,
                    style: BakeryTheme.subtitleText(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: AppointmentStrings.yourName,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? AppointmentStrings.requiredField : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: AppointmentStrings.phone,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? AppointmentStrings.requiredField : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: AppointmentStrings.emailOptional,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: AppointmentStrings.notesOptional,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(AppointmentStrings.confirmBooking),
          ),
        ],
      ),
    );
  }
}
