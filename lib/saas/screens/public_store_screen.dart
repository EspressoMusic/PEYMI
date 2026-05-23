import 'package:flutter/material.dart';

import '../../core/policy_consent_store.dart';
import '../../widgets/policy_consent_gate.dart';
import '../data/saas_repository.dart';
import '../models/saas_models.dart';
import 'public_appointment_screen.dart';
import 'public_product_store_body.dart';

class PublicStoreScreen extends StatefulWidget {
  const PublicStoreScreen({super.key, required this.slug});

  final String slug;

  @override
  State<PublicStoreScreen> createState() => _PublicStoreScreenState();
}

class _PublicStoreScreenState extends State<PublicStoreScreen> {
  SaasBusiness? _business;
  var _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final business = await SaasRepository.instance.fetchBusinessBySlug(widget.slug);
      if (business == null) {
        setState(() {
          _message = 'Store not found.';
          _loading = false;
        });
        return;
      }
      if (!business.isPubliclyVisible) {
        setState(() {
          _business = business;
          _message = 'This business is currently unavailable.';
          _loading = false;
        });
        return;
      }
      setState(() {
        _business = business;
        _loading = false;
        if (!business.acceptsCustomers) {
          _message = 'This business is currently unavailable.';
        }
      });
    } catch (e) {
      setState(() {
        _message = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always return the same wrapper type so this State's element tree stays stable.
    return PublicStoreView(
      loading: _loading,
      business: _business,
      message: _message,
    );
  }
}

/// Renders product store or appointment calendar without route replacement.
class PublicStoreView extends StatelessWidget {
  const PublicStoreView({
    super.key,
    required this.loading,
    this.business,
    this.message,
  });

  final bool loading;
  final SaasBusiness? business;
  final String? message;

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (loading) {
      body = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (message != null && business == null) {
      body = Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(message!, style: const TextStyle(fontSize: 18))),
      );
    } else {
      final b = business!;
      if (b.isAppointmentMode) {
        body = PublicAppointmentScreen(
          key: ValueKey('public-appt-${b.id}-${b.storeMode}'),
          business: b,
        );
      } else {
        body = Scaffold(
          key: ValueKey('public-products-${b.id}-${b.storeMode}'),
          appBar: AppBar(title: const SizedBox.shrink()),
          body: PublicProductStoreBody(business: b, bannerMessage: message),
        );
      }
    }

    return PolicyConsentGate(
      audience: PolicyAudience.customer,
      child: body,
    );
  }
}
