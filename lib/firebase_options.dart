import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase options from `--dart-define` (see `.env.example` / `google-services.json`).
abstract final class DefaultFirebaseOptions {
  static bool get isConfigured => _projectId.isNotEmpty && _appId.isNotEmpty;

  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
  static const _apiKey = String.fromEnvironment('FIREBASE_ANDROID_API_KEY', defaultValue: '');
  static const _appId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID', defaultValue: '');
  static const _senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '');

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase push is not configured for web.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('Firebase push is not configured for iOS yet.');
      default:
        throw UnsupportedError('Firebase push is not supported on this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _senderId,
    projectId: _projectId,
  );
}
