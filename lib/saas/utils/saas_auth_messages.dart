import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_locale.dart';

abstract final class SaasAuthMessages {
  static String formatError(Object error) {
    final strings = AppLocale.instance.s;
    if (error is AuthException) {
      final code = error.code ?? '';
      final msg = error.message.toLowerCase();
      if (code == 'email_not_confirmed' || msg.contains('email not confirmed')) {
        return strings.authEmailNotConfirmed;
      }
    }
    final text = error.toString();
    if (text.contains('email_not_confirmed') || text.contains('Email not confirmed')) {
      return strings.authEmailNotConfirmed;
    }
    return text.replaceFirst('AuthApiException(', '').replaceFirst('AuthException(', '').replaceAll(')', '');
  }

  static bool isEmailNotConfirmed(Object error) {
    if (error is AuthException) {
      return error.code == 'email_not_confirmed' ||
          error.message.toLowerCase().contains('email not confirmed');
    }
    final text = error.toString();
    return text.contains('email_not_confirmed') || text.contains('Email not confirmed');
  }
}
