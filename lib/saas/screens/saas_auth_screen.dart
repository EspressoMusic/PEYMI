import 'package:flutter/material.dart';

import '../../core/app_locale.dart';
import '../../core/app_theme_mode.dart';
import '../../core/bakery_navigator.dart';
import '../../core/manager_credentials_store.dart';
import '../../widgets/legal_links_row.dart';
import '../data/saas_repository.dart';
import '../manager_login_flow.dart';
import '../utils/saas_auth_messages.dart';

class SaasAuthScreen extends StatefulWidget {
  const SaasAuthScreen({super.key});

  @override
  State<SaasAuthScreen> createState() => _SaasAuthScreenState();
}

class _SaasAuthScreenState extends State<SaasAuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _signUp = false;
  var _loading = false;
  var _rememberEmail = false;
  String? _error;
  var _showResendConfirmation = false;
  String? _info;

  AppStrings get strings => AppLocale.instance.s;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final saved = await ManagerCredentialsStore.instance.loadRememberedOwnerEmail();
    if (!mounted || saved == null) return;
    setState(() {
      _email.text = saved;
      _rememberEmail = true;
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _resendConfirmation() async {
    final email = _email.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SaasRepository.instance.resendSignupConfirmation(email);
      if (!mounted) return;
      setState(() => _info = strings.authEmailConfirmSent);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = SaasAuthMessages.formatError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
      _showResendConfirmation = false;
    });
    try {
      final repo = SaasRepository.instance;
      final email = _email.text.trim();
      final password = _password.text;
      if (_signUp) {
        final signedIn = await repo.signUpWithEmail(email: email, password: password);
        if (!signedIn) {
          setState(() {
            _signUp = false;
            _info = strings.authSignUpPendingConfirm;
            _showResendConfirmation = true;
          });
          return;
        }
      } else {
        await repo.signInWithEmail(email: email, password: password);
      }
      if (repo.currentUser == null) {
        setState(() {
          _error = _signUp ? strings.authSignUpPendingConfirm : strings.authEmailNotConfirmed;
          _showResendConfirmation = true;
        });
        return;
      }
      await ManagerCredentialsStore.instance.saveRememberedOwnerEmail(
        email: email,
        remember: _rememberEmail,
      );
      await repo.fetchCurrentProfile();
      if (!mounted) return;
      popRouteSafely(context, true);
    } catch (e) {
      setState(() {
        _error = SaasAuthMessages.formatError(e);
        _showResendConfirmation = SaasAuthMessages.isEmailNotConfirmed(e);
      });
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
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: bakeryInputDecoration(context, label: 'Email', icon: Icons.email_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: bakeryInputDecoration(context, label: 'Password', icon: Icons.lock_outline),
          ),
          CheckboxListTile(
            value: _rememberEmail,
            onChanged: _loading ? null : (v) => setState(() => _rememberEmail = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(strings.managerRememberEmail, style: BakeryTheme.subtitleText(context, fontSize: 14)),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: _loading
                  ? null
                  : () => showOwnerAccountPasswordResetSheet(context),
              child: Text(strings.managerForgotPassword),
            ),
          ),
          if (_info != null) ...[
            const SizedBox(height: 12),
            Text(_info!, style: BakeryTheme.subtitleText(context, fontSize: 14, height: 1.4)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red, height: 1.35)),
          ],
          if (_showResendConfirmation) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: _loading ? null : _resendConfirmation, child: Text(strings.authResendConfirmation)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: Text(_loading ? 'Please wait…' : (_signUp ? 'Create account' : 'Sign in')),
          ),
          TextButton(
            onPressed: _loading ? null : () => setState(() => _signUp = !_signUp),
            child: Text(_signUp ? 'Already have an account? Sign in' : 'Need an account? Sign up'),
          ),
          const LegalLinksRow(),
        ],
      ),
    );
  }
}
