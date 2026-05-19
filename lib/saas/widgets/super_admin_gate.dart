import 'package:flutter/material.dart';

import '../data/saas_repository.dart';
import '../screens/super_admin_screen.dart';

/// Blocks Super Admin UI unless [profiles.role] is super_admin (verified via Supabase).
class SuperAdminGate extends StatefulWidget {
  const SuperAdminGate({super.key});

  @override
  State<SuperAdminGate> createState() => _SuperAdminGateState();
}

class _SuperAdminGateState extends State<SuperAdminGate> {
  var _checking = true;
  var _allowed = false;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    try {
      await SaasRepository.instance.requireSuperAdmin();
      if (mounted) {
        setState(() {
          _allowed = true;
          _checking = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _checking = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Access denied')),
          );
          Navigator.of(context).maybePop();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_allowed) {
      return const Scaffold(
        body: Center(child: Text('Access denied')),
      );
    }
    return const SuperAdminScreen();
  }
}
