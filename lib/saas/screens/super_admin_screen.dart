import 'package:flutter/material.dart';

import '../../core/app_theme_mode.dart';
import '../../core/public_store_links.dart';
import '../data/saas_repository.dart';
import '../models/saas_models.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  List<SaasBusinessAdminRow> _rows = [];
  var _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await SaasRepository.instance.fetchCurrentProfile();
      if (profile?.isSuperAdmin != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Access denied')),
          );
          Navigator.pop(context);
        }
        return;
      }
      final rows = await SaasRepository.instance.fetchAllBusinessesForSuperAdmin();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  List<SaasBusinessAdminRow> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _rows;
    return _rows.where((r) {
      return r.business.businessName.toLowerCase().contains(q) ||
          r.business.slug.toLowerCase().contains(q) ||
          (r.ownerEmail?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const SizedBox.shrink()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: bakeryInputDecoration(context, label: 'Search', icon: Icons.search),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final row = _filtered[index];
                      final b = row.business;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ExpansionTile(
                          title: Text(b.businessName, style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(
                            '${PublicStoreLinks.publicUrlForSlug(b.slug)} · ${row.ownerEmail ?? '—'}',
                          ),
                          children: [
                            ListTile(
                              dense: true,
                              title: Text('Status: ${b.subscriptionStatus} · active: ${b.isActive}'),
                            ),
                            ListTile(
                              dense: true,
                              title: Text(
                                'Products: ${row.productCount} · Orders: ${row.orderCount} · Appointments: ${row.appointmentCount}',
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton(
                                  onPressed: () => _setStatus(b, isActive: true, status: 'active'),
                                  child: const Text('Activate'),
                                ),
                                TextButton(
                                  onPressed: () => _setStatus(b, isActive: false, status: 'suspended'),
                                  child: const Text('Suspend'),
                                ),
                                TextButton(
                                  onPressed: () => _setStatus(b, isActive: true, status: 'trial'),
                                  child: const Text('Trial'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _setStatus(SaasBusiness b, {required bool isActive, required String status}) async {
    await SaasRepository.instance.superAdminUpdateBusiness(
      businessId: b.id,
      isActive: isActive,
      subscriptionStatus: status,
    );
    await _load();
  }
}
