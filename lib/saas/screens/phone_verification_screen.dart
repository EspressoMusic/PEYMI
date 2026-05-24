import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_theme_mode.dart';
import '../../core/bakery_navigator.dart';
import '../../widgets/bakery_celebration.dart';
import '../data/saas_repository.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  var _codeSent = false;
  var _loading = false;
  String? _error;
  String? _devCodeHint;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final devCode = await SaasRepository.instance.sendPhoneOtp(_phone.text.trim());
      setState(() {
        _codeSent = true;
        _devCodeHint = devCode;
        if (devCode != null) _code.text = devCode;
      });
      if (mounted && devCode != null) {
        unawaited(showBakeryNoticeBanner(
          context,
          title: 'Dev code (no SMS): $devCode',
          isError: false,
        ));
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SaasRepository.instance.verifyPhoneOtp(
        phone: _phone.text.trim(),
        code: _code.text.trim(),
      );
      if (!mounted) return;
      popRouteSafely(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const SizedBox.shrink()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'To create a store, please verify your phone number.',
            style: BakeryTheme.subtitleText(context, fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: bakeryInputDecoration(context, label: 'Phone', icon: Icons.phone_outlined),
          ),
          const SizedBox(height: 12),
          if (_codeSent) ...[
            if (_devCodeHint != null)
              Card(
                color: Colors.orange.withValues(alpha: 0.15),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'SMS is not configured. Use this code: $_devCodeHint',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            if (_devCodeHint != null) const SizedBox(height: 12),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              decoration: bakeryInputDecoration(context, label: 'Verification code', icon: Icons.sms_outlined),
            ),
            const SizedBox(height: 12),
          ],
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : (_codeSent ? _verify : _sendCode),
            child: Text(_loading ? 'Please wait…' : (_codeSent ? 'Verify' : 'Send code')),
          ),
        ],
      ),
    );
  }
}
