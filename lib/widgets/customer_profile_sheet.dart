import 'package:flutter/material.dart';

import '../core/app_locale.dart';
import '../core/app_theme_mode.dart';
import '../core/bakery_navigator.dart';
import '../core/bakery_square_palette.dart';
import '../core/customer_profile_store.dart';
import '../core/keyboard_safe.dart';
import 'customer_name_field.dart';
import 'bakery_celebration.dart';

/// Settings sheet: sign in / update / sign out customer profile.
Future<void> showCustomerProfileSheet(BuildContext context) async {
  final strings = AppLocale.instance.s;
  await showBakeryDialog<void>(
    context: context,
    child: _CustomerProfileSheetBody(title: strings.customerProfileTitle),
  );
}

class _CustomerProfileSheetBody extends StatefulWidget {
  const _CustomerProfileSheetBody({required this.title});

  final String title;

  @override
  State<_CustomerProfileSheetBody> createState() => _CustomerProfileSheetBodyState();
}

class _CustomerProfileSheetBodyState extends State<_CustomerProfileSheetBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final profile = CustomerProfileStore.instance;
    _nameCtrl = TextEditingController(text: profile.displayName);
    _phoneCtrl = TextEditingController(text: profile.phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (!mounted) return;
    await popThen(context, () async {
      await CustomerProfileStore.instance.signIn(displayName: name, phone: phone);
      final host = bakeryRootContext;
      if (host != null && host.mounted) {
        await showBakeryUpdateBanner(host, title: AppLocale.instance.s.customerProfileSaved);
      }
    });
  }

  Future<void> _signOut() async {
    if (!mounted) return;
    await popThen(context, () async {
      await CustomerProfileStore.instance.signOut();
      final host = bakeryRootContext;
      if (host != null && host.mounted) {
        await showBakeryUpdateBanner(
          host,
          title: AppLocale.instance.s.customerSignedOut,
          playSound: false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocale.instance.s;
    final signedIn = CustomerProfileStore.instance.isSignedIn;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          if (signedIn) ...[
            const SizedBox(height: 12),
            Text(
              strings.customerSignedInAs(
                CustomerProfileStore.instance.displayName,
                CustomerProfileStore.instance.phone,
              ),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
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
          ),
          const SizedBox(height: 16),
          _CustomerProfileActionButton(
            label: signedIn ? strings.save : strings.customerSignIn,
            onPressed: _save,
          ),
          if (signedIn) ...[
            const SizedBox(height: 8),
            _CustomerProfileActionButton(
              label: strings.customerSignOut,
              onPressed: _signOut,
              secondary: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// Cream-square tap target — label stays inside the bordered pill (unlike themed [FilledButton] on panel fill).
class _CustomerProfileActionButton extends StatelessWidget {
  const _CustomerProfileActionButton({
    required this.label,
    required this.onPressed,
    this.secondary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final fill = secondary ? Colors.transparent : BakeryTheme.buttonFill(context);
    final labelColor = secondary ? BakeryTheme.buttonFill(context) : BakeryTheme.buttonOnFill(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(18),
            border: secondary
                ? Border.all(color: BakeryTheme.buttonFill(context), width: 1.6)
                : null,
          ),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: Center(
              child: Text(
                label,
                style: BakeryTheme.text(
                  context,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: labelColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
