import 'package:flutter/material.dart';

import '../core/app_locale.dart';
import '../core/bakery_navigator.dart';
import '../core/customer_profile_store.dart';
import '../core/keyboard_safe.dart';
import 'customer_name_field.dart';

class CustomerContact {
  const CustomerContact({required this.name, required this.phone});

  final String name;
  final String phone;
}

/// Returns saved profile or prompts for name + phone before placing an order.
Future<CustomerContact?> ensureCustomerContactForOrder(BuildContext context) async {
  final profile = CustomerProfileStore.instance;
  if (profile.isSignedIn) {
    return CustomerContact(name: profile.displayName, phone: profile.phone);
  }

  return showBakeryDialog<CustomerContact>(
    context: context,
    barrierDismissible: false,
    child: const _OrderContactForm(),
  );
}

class _OrderContactForm extends StatefulWidget {
  const _OrderContactForm();

  @override
  State<_OrderContactForm> createState() => _OrderContactFormState();
}

class _OrderContactFormState extends State<_OrderContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  var _remember = true;

  @override
  void initState() {
    super.initState();
    final profile = CustomerProfileStore.instance;
    if (profile.displayName.isNotEmpty) _nameCtrl.text = profile.displayName;
    if (profile.phone.isNotEmpty) _phoneCtrl.text = profile.phone;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _nameCtrl.text.trim();
    final phone = CustomerProfileStore.normalizePhone(_phoneCtrl.text.trim())!;
    final remember = _remember;
    if (!mounted) return;
    await popThen(
      context,
      () async {
        if (remember) {
          await CustomerProfileStore.instance.signIn(displayName: name, phone: phone);
        }
      },
      result: CustomerContact(name: name, phone: phone),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocale.instance.s;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.orderContactTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            strings.orderContactHint,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CustomerNameField(
            controller: _nameCtrl,
            label: strings.customerDisplayName,
            textInputAction: TextInputAction.next,
            validator: (v) => CustomerNameField.validate(v, strings),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: strings.yourPhone,
              border: const OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return strings.fillAllFields;
              if (CustomerProfileStore.normalizePhone(v) == null) {
                return strings.invalidPhone;
              }
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _remember,
            onChanged: (v) => setState(() => _remember = v ?? true),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(strings.rememberMeForOrders),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submit,
            child: Text(strings.confirmOrder),
          ),
          TextButton(
            onPressed: () => popRouteSafely(context),
            child: Text(strings.cancel),
          ),
        ],
      ),
    );
  }
}
