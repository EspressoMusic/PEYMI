import 'dart:io';

/// Stripe keys and backend URL — pass at build/run time with --dart-define.
abstract final class StripeConfig {
  static const publishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static const backendUrlOverride = String.fromEnvironment(
    'STRIPE_BACKEND_URL',
    defaultValue: '',
  );

  static bool get isConfigured =>
      publishableKey.isNotEmpty && publishableKey.startsWith('pk_');

  static String get backendUrl {
    if (backendUrlOverride.isNotEmpty) return backendUrlOverride;
    if (Platform.isAndroid) return 'http://10.0.2.2:4242';
    return 'http://127.0.0.1:4242';
  }
}
