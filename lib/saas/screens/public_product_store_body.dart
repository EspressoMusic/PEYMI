import 'package:flutter/material.dart';

import '../../core/app_theme_mode.dart';
import '../data/saas_repository.dart';
import '../models/saas_models.dart';

class PublicProductStoreBody extends StatefulWidget {
  const PublicProductStoreBody({super.key, required this.business, this.bannerMessage});

  final SaasBusiness business;
  final String? bannerMessage;

  @override
  State<PublicProductStoreBody> createState() => _PublicProductStoreBodyState();
}

class _PublicProductStoreBodyState extends State<PublicProductStoreBody> {
  List<SaasProduct> _products = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = widget.business.acceptsCustomers
        ? await SaasRepository.instance.fetchActiveProducts(widget.business.id)
        : <SaasProduct>[];
    if (!mounted) return;
    setState(() {
      _products = products;
      _loading = false;
    });
  }

  Future<void> _placeOrder() async {
    final b = widget.business;
    if (!b.acceptsCustomers) return;
    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Place order'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Your name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
        ],
      ),
    );
    if (ok != true || nameCtrl.text.trim().isEmpty) return;
    await SaasRepository.instance.createOrder(
      businessId: b.id,
      customerName: nameCtrl.text.trim(),
      items: [
        if (_products.isNotEmpty)
          {'product_id': _products.first.id, 'name': _products.first.name, 'qty': 1},
      ],
      totalPrice: _products.isNotEmpty ? _products.first.price : 0,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order submitted')));
    }
  }

  Future<void> _showMessageSheet() async {
    final b = widget.business;
    final ctrl = TextEditingController();
    final nameCtrl = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.viewPaddingOf(ctx).bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Message')),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  await SaasRepository.instance.sendCustomerMessage(
                    businessId: b.id,
                    message: ctrl.text.trim(),
                    customerName: nameCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Send'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.business;
    final canInteract = b.acceptsCustomers && widget.bannerMessage == null;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.bannerMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              widget.bannerMessage!,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ),
        if (b.logoUrl != null && b.logoUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(b.logoUrl!, height: 120, width: double.infinity, fit: BoxFit.cover),
          ),
        if (b.description != null && b.description!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(b.description!, style: BakeryTheme.subtitleText(context, height: 1.4)),
        ],
        const SizedBox(height: 16),
        Text('Products & services', style: BakeryTheme.text(context, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (_products.isEmpty)
          Text('No items listed yet.', style: BakeryTheme.subtitleText(context))
        else
          ..._products.map(
            (p) => Card(
              child: ListTile(
                title: Text(p.name),
                subtitle: p.description != null ? Text(p.description!) : null,
                trailing: Text('₪${p.price.toStringAsFixed(0)}'),
              ),
            ),
          ),
        const SizedBox(height: 24),
        if (canInteract) ...[
          FilledButton(onPressed: _placeOrder, child: const Text('Order')),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _showMessageSheet, child: const Text('Contact / Message')),
        ],
      ],
    );
  }
}
