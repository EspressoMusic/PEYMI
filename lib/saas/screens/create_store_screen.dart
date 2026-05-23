import 'package:flutter/material.dart';

import '../../core/app_locale.dart';
import '../../core/app_theme_mode.dart';
import '../../widgets/legal_acceptance_checkbox.dart';
import '../../widgets/legal_links_row.dart';
import '../data/saas_repository.dart';
import '../../core/manager_store.dart';
import '../models/saas_models.dart';
import '../../core/public_store_links.dart';
import '../utils/slug_utils.dart';
import 'owner_dashboard_screen.dart';

class CreateStoreScreen extends StatefulWidget {
  const CreateStoreScreen({super.key});

  @override
  State<CreateStoreScreen> createState() => _CreateStoreScreenState();
}

class _CreateStoreScreenState extends State<CreateStoreScreen> {
  final _name = TextEditingController();
  final _slug = TextEditingController();
  final _description = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _businessType = TextEditingController();
  var _loading = false;
  var _legalAccepted = false;
  var _checkingLegal = true;
  String? _error;
  String? _slugError;

  @override
  void initState() {
    super.initState();
    _loadLegalState();
  }

  Future<void> _loadLegalState() async {
    try {
      final ok = await SaasRepository.instance.hasAcceptedCurrentLegal();
      if (!mounted) return;
      setState(() {
        _legalAccepted = ok;
        _checkingLegal = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _checkingLegal = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _description.dispose();
    _phone.dispose();
    _address.dispose();
    _businessType.dispose();
    super.dispose();
  }

  void _onSlugChanged(String value) {
    final normalized = normalizeSlug(value);
    setState(() {
      _slug.text = normalized;
      _slug.selection = TextSelection.collapsed(offset: normalized.length);
      _slugError = null;
    });
  }

  Future<void> _checkSlug() async {
    final slug = normalizeSlug(_slug.text);
    if (slug.isEmpty) return;
    final ok = await SaasRepository.instance.isSlugAvailable(slug);
    if (!mounted) return;
    setState(() {
      _slugError = ok
          ? null
          : 'This store link is already taken. Please choose another one.';
    });
  }

  Future<void> _submit() async {
    final slug = normalizeSlug(_slug.text);
    if (_name.text.trim().isEmpty || slug.isEmpty) {
      setState(() => _error = 'Store name and store link are required.');
      return;
    }
    if (!_legalAccepted) {
      setState(() => _error = AppLocale.instance.s.legalMustAccept);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SaasRepository.instance.recordLegalAcceptance();
      final result = await SaasRepository.instance.createBusinessViaEdge(
        businessName: _name.text.trim(),
        slug: slug,
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        businessType: _businessType.text.trim().isEmpty ? null : _businessType.text.trim(),
      );
      final businessJson = result['business'] as Map<String, dynamic>?;
      if (!mounted || businessJson == null) return;
      final business = SaasBusiness.fromJson(businessJson);
      await ManagerStore.instance.linkOnlineBusiness(
        id: business.id,
        slug: business.slug,
        storeMode: business.storeMode,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your store is ready.')),
      );
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OwnerDashboardScreen(
            business: business,
            justCreated: true,
          ),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
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
            controller: _name,
            decoration: bakeryInputDecoration(context, label: 'Store Name *', icon: Icons.storefront),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _slug,
            onChanged: _onSlugChanged,
            onEditingComplete: _checkSlug,
            decoration: bakeryInputDecoration(context, label: 'Store Link *', icon: Icons.link).copyWith(
              errorText: _slugError,
              helperText:
                  'Public link: ${PublicStoreLinks.publicUrlForSlug(_slug.text.isEmpty ? 'your-store' : _slug.text)}',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 3,
            decoration: bakeryInputDecoration(context, label: 'Description', icon: Icons.notes),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            decoration: bakeryInputDecoration(context, label: 'Phone', icon: Icons.phone),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            decoration: bakeryInputDecoration(context, label: 'Address', icon: Icons.place_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _businessType,
            decoration: bakeryInputDecoration(context, label: 'Business type', icon: Icons.category_outlined),
          ),
          const SizedBox(height: 16),
          const LegalLinksRow(),
          if (_checkingLegal)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            LegalAcceptanceCheckbox(
              value: _legalAccepted,
              onChanged: (v) {
                if (_loading) return;
                setState(() => _legalAccepted = v ?? false);
              },
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: Text(_loading ? 'Creating…' : 'Create Store'),
          ),
        ],
      ),
    );
  }
}
