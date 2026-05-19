import 'package:flutter/material.dart';

import '../../core/app_theme_mode.dart';
import '../../core/manager_store.dart';
import '../../core/public_store_links.dart';
import '../data/saas_repository.dart';
import '../models/saas_models.dart';
import '../widgets/owner_appointment_panel.dart';
import '../widgets/store_mode_selector.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({required this.business, this.justCreated = false});

  final SaasBusiness business;
  final bool justCreated;

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  late SaasBusiness _business;
  List<SaasProduct> _products = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _business = widget.business;
    ManagerStore.instance.linkOnlineBusiness(
      id: _business.id,
      slug: _business.slug,
      storeMode: _business.storeMode,
    );
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final fresh = await SaasRepository.instance.fetchBusinessBySlug(_business.slug);
    final products = fresh != null
        ? await SaasRepository.instance.fetchActiveProducts(fresh.id)
        : <SaasProduct>[];
    if (!mounted) return;
    setState(() {
      if (fresh != null) {
        _business = fresh;
        ManagerStore.instance.linkOnlineBusiness(
          id: fresh.id,
          slug: fresh.slug,
          storeMode: fresh.storeMode,
        );
      }
      _products = products;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = _business.ownerDashboardUnlocked;

    return Scaffold(
      appBar: AppBar(
        title: Text(_business.businessName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.justCreated)
                  Card(
                    color: Colors.green.withValues(alpha: 0.12),
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                        'Your store is ready.',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ),
                if (_business.subscriptionStatus == 'past_due')
                  Card(
                    color: Colors.orange.withValues(alpha: 0.15),
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                        'Payment issue detected. Please update your payment method.',
                      ),
                    ),
                  ),
                if (!unlocked)
                  Card(
                    color: Colors.red.withValues(alpha: 0.1),
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                        'Your business is currently inactive. Please reactivate your subscription to continue.',
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                StoreModeSelector(
                  business: _business,
                  onBusinessChanged: (b) => setState(() => _business = b),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pushNamed(
                      PublicStoreLinks.internalRouteForSlug(_business.slug),
                    ),
                    child: const Text('Open Store'),
                  ),
                ),
                const SizedBox(height: 16),
                if (unlocked) ...[
                  if (_business.isAppointmentMode) ...[
                    OwnerAppointmentPanel(business: _business),
                  ] else ...[
                    Text('Products', style: BakeryTheme.text(context, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    if (_products.isEmpty)
                      Text(
                        'No products yet. Add products from your dashboard (coming soon in app UI).',
                        style: BakeryTheme.subtitleText(context),
                      )
                    else
                      ..._products.map(
                        (p) => ListTile(
                          title: Text(p.name),
                          subtitle: Text('₪${p.price.toStringAsFixed(0)}'),
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Orders, appointments, and messages are stored in Supabase and protected by RLS.',
                    style: BakeryTheme.subtitleText(context, fontSize: 13),
                  ),
                ],
              ],
            ),
    );
  }
}
