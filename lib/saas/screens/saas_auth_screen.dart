import 'package:flutter/material.dart';

import '../../core/app_theme_mode.dart';
import '../data/saas_repository.dart';

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
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = SaasRepository.instance;
      final email = _email.text.trim();
      final password = _password.text;
      if (_signUp) {
        await repo.signUpWithEmail(email: email, password: password);
      } else {
        await repo.signInWithEmail(email: email, password: password);
      }
      if (repo.currentUser == null) {
        setState(() {
          _error = _signUp
              ? 'Account may be created, but you are not signed in yet. Tap "Sign in" below with the same email and password.'
              : 'Sign-in failed. Check email and password, or confirm your email in Supabase Auth.';
        });
        return;
      }
      await repo.fetchCurrentProfile();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_signUp ? 'Sign up' : 'Sign in')),
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
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
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
        ],
      ),
    );
  }
}
