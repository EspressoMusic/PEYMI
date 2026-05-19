import 'package:flutter/material.dart';

import '../core/app_locale.dart';
import '../core/app_theme_mode.dart';
import '../core/supabase/supabase_bootstrap.dart';
import '../saas/data/saas_repository.dart';
import '../saas/models/saas_models.dart';

/// Customer tab: business info and listed services (active products).
class CustomerBusinessServicesTab extends StatefulWidget {
  const CustomerBusinessServicesTab({super.key, required this.businessSlug});

  final String businessSlug;

  @override
  State<CustomerBusinessServicesTab> createState() => _CustomerBusinessServicesTabState();
}

class _CustomerBusinessServicesTabState extends State<CustomerBusinessServicesTab> {
  SaasBusiness? _business;
  List<SaasProduct> _services = [];
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!SupabaseBootstrap.isReady) {
      setState(() {
        _error = AppLocale.instance.isHebrew ? 'שרת לא מוגדר' : 'Server not configured';
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final business = await SaasRepository.instance.fetchBusinessBySlug(widget.businessSlug);
      if (!mounted) return;
      if (business == null) {
        setState(() {
          _error = AppLocale.instance.isHebrew ? 'חנות לא נמצאה' : 'Store not found';
          _loading = false;
        });
        return;
      }
      final products = await SaasRepository.instance.fetchActiveProducts(business.id);
      if (!mounted) return;
      setState(() {
        _business = business;
        _services = products;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocale.instance.s;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    }

    final b = _business!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            strings.customerServicesTitle,
            style: BakeryTheme.text(context, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.businessName, style: BakeryTheme.text(context, fontSize: 18, fontWeight: FontWeight.w800)),
                  if (b.businessType != null && b.businessType!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(b.businessType!, style: BakeryTheme.subtitleText(context)),
                  ],
                  if (b.description != null && b.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(b.description!, style: BakeryTheme.text(context)),
                  ],
                  if (b.phone != null && b.phone!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(b.phone!, style: BakeryTheme.text(context)),
                      ],
                    ),
                  ],
                  if (b.address != null && b.address!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.place_outlined, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(b.address!, style: BakeryTheme.text(context))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            strings.customerServicesList,
            style: BakeryTheme.text(context, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (_services.isEmpty)
            Text(strings.customerNoServices, style: BakeryTheme.subtitleText(context))
          else
            ..._services.map(
              (p) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(p.name, style: BakeryTheme.text(context, fontWeight: FontWeight.w600)),
                  subtitle: p.description != null && p.description!.trim().isNotEmpty
                      ? Text(p.description!)
                      : null,
                  trailing: Text(
                    '₪${p.price.toStringAsFixed(0)}',
                    style: BakeryTheme.text(context, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
