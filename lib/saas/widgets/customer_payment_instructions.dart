import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_theme_mode.dart';
import '../data/saas_repository.dart';
import '../models/business_payment_settings.dart';
import '../utils/payment_strings.dart';

/// Payment instructions shown to customers after order / appointment (pilot: no card fields).
class CustomerPaymentInstructionsBody extends StatelessWidget {
  const CustomerPaymentInstructionsBody({super.key, required this.settings});

  final BusinessPaymentSettings settings;

  Future<void> _openLink(BuildContext context, String raw) async {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || !uri.hasScheme) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(PaymentStrings.isHebrew ? 'קישור לא תקין' : 'Invalid payment link')),
      );
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(PaymentStrings.isHebrew ? 'לא ניתן לפתוח קישור' : 'Could not open link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final instructions = settings.paymentInstructions?.trim();
    final link = settings.externalPaymentLink?.trim();
    final phone = settings.paymentPhone?.trim();
    final currency = settings.currency.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (currency.isNotEmpty && currency != 'USD')
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              PaymentStrings.isHebrew ? 'מטבע: $currency' : 'Currency: $currency',
              style: BakeryTheme.subtitleText(context, fontWeight: FontWeight.w600),
            ),
          ),
        if (instructions != null && instructions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(instructions, style: BakeryTheme.subtitleText(context, height: 1.45)),
        ],
        if (link != null && link.isNotEmpty) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _openLink(context, link),
            icon: const Icon(Icons.open_in_new),
            label: Text(PaymentStrings.payNow),
          ),
        ],
        if (phone != null && phone.isNotEmpty) ...[
          const SizedBox(height: 12),
          SelectableText(
            PaymentStrings.paymentPhone(phone),
            style: BakeryTheme.text(context, fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }
}

/// Success dialog after customer order or appointment booking.
Future<void> showCustomerPaymentSuccessDialog({
  required BuildContext context,
  required String businessId,
  required bool isAppointment,
}) async {
  final settings = await SaasRepository.instance.fetchPaymentSettings(businessId);
  if (!context.mounted) return;

  final showPayment = settings?.paymentEnabled == true;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(
          isAppointment ? PaymentStrings.appointmentSuccessTitle : PaymentStrings.orderSuccessTitle,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showPayment) ...[
                Text(PaymentStrings.payBusinessHint, style: BakeryTheme.subtitleText(ctx)),
                const SizedBox(height: 12),
                CustomerPaymentInstructionsBody(settings: settings!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(PaymentStrings.close),
          ),
        ],
      );
    },
  );
}
