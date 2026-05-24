import 'package:flutter/material.dart';

import '../core/app_fonts.dart';
import '../core/app_locale.dart';
import '../core/app_theme_mode.dart';

/// Name field for orders / profile — Hebrew, English, and mixed input.
class CustomerNameField extends StatelessWidget {
  const CustomerNameField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.useBakeryDecoration = false,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final bool useBakeryDecoration;

  static String? validate(String? value, AppStrings strings) {
    if (value == null || value.trim().isEmpty) return strings.fillAllFields;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.instance;
    final fieldStyle = AppFonts.style(
      fontSize: 16,
      fontWeight: AppFonts.regular,
      color: BakeryTheme.body(context),
    );

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.name,
      textInputAction: textInputAction,
      textCapitalization: TextCapitalization.words,
      textDirection: locale.direction,
      autofillHints: const [AutofillHints.name],
      style: fieldStyle,
      decoration: useBakeryDecoration
          ? bakeryInputDecoration(context, label: label, icon: Icons.person_outline)
          : InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}
