import '../../firebase_options.dart';

abstract final class PushConfig {
  static bool get isConfigured => DefaultFirebaseOptions.isConfigured;
}
