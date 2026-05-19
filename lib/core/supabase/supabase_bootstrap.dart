import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

abstract final class SupabaseBootstrap {
  static bool _ready = false;

  static bool get isReady => _ready && SupabaseConfig.isConfigured;

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    if (!SupabaseConfig.isConfigured) {
      _ready = false;
      return;
    }
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _ready = true;
  }
}
