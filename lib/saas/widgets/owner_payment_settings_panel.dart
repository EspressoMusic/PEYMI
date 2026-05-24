import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/bakery_celebration.dart';
import '../../core/app_theme_mode.dart';
import '../data/saas_repository.dart';
import '../models/business_payment_settings.dart';
import '../models/saas_models.dart';
import '../utils/payment_strings.dart';

/// Owner configures customer-to-business payment instructions (pilot: manual / external only).
class OwnerPaymentSettingsPanel extends StatefulWidget {
  const OwnerPaymentSettingsPanel({super.key, required this.business});

  final SaasBusiness business;

  @override
  State<OwnerPaymentSettingsPanel> createState() => _OwnerPaymentSettingsPanelState();
}

/// UI preset mapped to [BusinessPaymentSettings] rows.
enum _OwnerPaymentPreset {
  disabled,
  manual,
  externalLink,
  payOnArrival,
  cashOnDelivery,
}

class _OwnerPaymentSettingsPanelState extends State<OwnerPaymentSettingsPanel> {
  var _loading = true;
  var _saving = false;
  _OwnerPaymentPreset _preset = _OwnerPaymentPreset.disabled;
  final _instructionsCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController(text: 'USD');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _instructionsCtrl.dispose();
    _linkCtrl.dispose();
    _phoneCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  _OwnerPaymentPreset _presetFromSettings(BusinessPaymentSettings? s) {
    if (s == null || !s.paymentEnabled) return _OwnerPaymentPreset.disabled;
    return switch (s.paymentMode) {
      'external_link' => _OwnerPaymentPreset.externalLink,
      'pay_on_arrival' => _OwnerPaymentPreset.payOnArrival,
      'cash_on_delivery' => _OwnerPaymentPreset.cashOnDelivery,
      _ => _OwnerPaymentPreset.manual,
    };
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final row = await SaasRepository.instance.fetchPaymentSettings(widget.business.id);
    if (!mounted) return;
    _preset = _presetFromSettings(row);
    _instructionsCtrl.text = row?.paymentInstructions ?? '';
    _linkCtrl.text = row?.externalPaymentLink ?? '';
    _phoneCtrl.text = row?.paymentPhone ?? '';
    _currencyCtrl.text = row?.currency ?? 'USD';
    setState(() => _loading = false);
  }

  BusinessPaymentSettings _buildSettings() {
    final enabled = _preset != _OwnerPaymentPreset.disabled;
    final mode = switch (_preset) {
      _OwnerPaymentPreset.externalLink => 'external_link',
      _OwnerPaymentPreset.payOnArrival => 'pay_on_arrival',
      _OwnerPaymentPreset.cashOnDelivery => 'cash_on_delivery',
      _ => 'manual',
    };
    return BusinessPaymentSettings(
      businessId: widget.business.id,
      paymentEnabled: enabled,
      paymentMode: mode,
      currency: _currencyCtrl.text.trim().isEmpty ? 'USD' : _currencyCtrl.text.trim(),
      paymentInstructions: _instructionsCtrl.text,
      externalPaymentLink: _preset == _OwnerPaymentPreset.externalLink ? _linkCtrl.text : null,
      paymentPhone: _phoneCtrl.text,
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await SaasRepository.instance.upsertPaymentSettings(_buildSettings());
      if (mounted) {
        await showBakeryUpdateBanner(context, title: PaymentStrings.settingsSaved);
      }
    } catch (e) {
      if (mounted) {
        unawaited(showBakeryNoticeBanner(context, title: '$e', isError: true));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final showLinkField = _preset == _OwnerPaymentPreset.externalLink;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              PaymentStrings.paymentSettingsTitle,
              style: BakeryTheme.text(context, fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              PaymentStrings.pilotDisclaimer,
              style: BakeryTheme.subtitleText(context, fontSize: 12, height: 1.35),
            ),
            const SizedBox(height: 16),
            _presetTile(_OwnerPaymentPreset.disabled, PaymentStrings.optionDisabled),
            _presetTile(_OwnerPaymentPreset.manual, PaymentStrings.optionManual),
            _presetTile(_OwnerPaymentPreset.externalLink, PaymentStrings.optionExternalLink),
            _presetTile(_OwnerPaymentPreset.payOnArrival, PaymentStrings.optionPayOnArrival),
            _presetTile(_OwnerPaymentPreset.cashOnDelivery, PaymentStrings.optionCashDelivery),
            const SizedBox(height: 12),
            TextField(
              controller: _instructionsCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: PaymentStrings.paymentInstructionsLabel,
                alignLabelWithHint: true,
              ),
            ),
            if (showLinkField) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _linkCtrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(labelText: PaymentStrings.externalLinkLabel),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: PaymentStrings.paymentPhoneLabel),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _currencyCtrl,
              decoration: InputDecoration(labelText: PaymentStrings.currencyLabel),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(PaymentStrings.saveSettings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetTile(_OwnerPaymentPreset value, String label) {
    return RadioListTile<_OwnerPaymentPreset>(
      value: value,
      groupValue: _preset,
      onChanged: (v) {
        if (v == null) return;
        setState(() => _preset = v);
      },
      title: Text(label, style: const TextStyle(fontSize: 14)),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}
