import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

import 'app_locale.dart';
import 'app_theme_mode.dart';
import 'stripe_config.dart';

class StripePaymentException implements Exception {
  StripePaymentException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// In-app Stripe Payment Sheet after order confirmation.
abstract final class StripePaymentService {
  static Future<void> initialize() async {
    if (!StripeConfig.isConfigured) return;
    Stripe.publishableKey = StripeConfig.publishableKey;
    await Stripe.instance.applySettings();
  }

  static Future<bool> payForOrder({
    required BuildContext context,
    required int amountAgorot,
    required String orderId,
    String? description,
  }) async {
    final strings = AppLocale.instance.s;

    if (!StripeConfig.isConfigured) {
      await _showSetupDialog(context);
      return false;
    }

    if (amountAgorot < 500) {
      throw StripePaymentException(strings.paymentMinimum);
    }

    final accent = BakeryTheme.accent(context);

    try {
      final clientSecret = await _createPaymentIntent(
        amountAgorot: amountAgorot,
        orderId: orderId,
        description: description ?? orderId,
      );

      if (!context.mounted) return false;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: strings.appTitle,
          style: ThemeMode.system,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: accent,
            ),
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return false;
      }
      throw StripePaymentException(e.error.localizedMessage ?? e.error.message ?? strings.paymentFailed);
    } on http.ClientException {
      throw StripePaymentException(strings.paymentServerUnreachable);
    }
  }

  static Future<String> _createPaymentIntent({
    required int amountAgorot,
    required String orderId,
    required String description,
  }) async {
    final uri = Uri.parse('${StripeConfig.backendUrl}/create-payment-intent');
    final response = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'amount': amountAgorot,
            'currency': 'ils',
            'orderId': orderId,
            'description': description,
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      String message = 'HTTP ${response.statusCode}';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['error'] != null) {
          message = body['error'].toString();
        }
      } catch (_) {}
      throw StripePaymentException(message);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final secret = data['clientSecret'] as String?;
    if (secret == null || secret.isEmpty) {
      throw StripePaymentException('Missing clientSecret from server');
    }
    return secret;
  }

  static Future<void> _showSetupDialog(BuildContext context) async {
    final strings = AppLocale.instance.s;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.paymentNotConfiguredTitle),
        content: SingleChildScrollView(
          child: Text(strings.paymentNotConfiguredBody, style: BakeryTheme.subtitleText(ctx, height: 1.4)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(strings.close)),
        ],
      ),
    );
  }
}
