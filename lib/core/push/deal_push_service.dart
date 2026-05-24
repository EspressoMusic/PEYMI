import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../app_locale.dart';
import '../manager_store.dart';
import '../supabase/supabase_bootstrap.dart';
import '../../firebase_options.dart';
import '../../saas/data/saas_repository.dart';
import 'push_config.dart';

const _dealChannelId = 'bizmi_deals';
const _dealChannelNameHe = 'מבצעים';

/// Registers FCM tokens and shows deal push notifications (even when app is in background).
abstract final class DealPushService {
  DealPushService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static var _initialized = false;
  static StreamSubscription<String>? _tokenRefreshSub;
  static VoidCallback? _onOpenDealsTab;

  static void setOnOpenDealsTab(VoidCallback? handler) {
    _onOpenDealsTab = handler;
  }

  static Future<void> init() async {
    if (_initialized || !PushConfig.isConfigured) return;

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (e, st) {
      debugPrint('DealPushService: Firebase init skipped ($e)\n$st');
      return;
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (_) => _onOpenDealsTab?.call(),
    );

    await _ensureAndroidChannel();

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((_) => _onOpenDealsTab?.call());

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _onOpenDealsTab?.call();
    }

    _tokenRefreshSub ??= messaging.onTokenRefresh.listen((_) => unawaited(_registerCurrentToken()));
    ManagerStore.instance.addListener(_onStoreChanged);

    await _registerCurrentToken();
    _initialized = true;
  }

  static void _onStoreChanged() {
    unawaited(_registerCurrentToken());
  }

  static Future<void> _ensureAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      _dealChannelId,
      _dealChannelNameHe,
      description: 'התראות על מבצעים חדשים',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _registerCurrentToken() async {
    if (!SupabaseBootstrap.isReady) return;
    final slug = ManagerStore.instance.linkedBusinessSlug?.trim().toLowerCase();
    if (slug == null || slug.isEmpty) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.length < 20) return;
      await SaasRepository.instance.registerStorePushToken(
        businessSlug: slug,
        fcmToken: token,
        locale: AppLocale.instance.isHebrew ? 'he' : 'en',
      );
    } catch (e, st) {
      debugPrint('DealPushService: token register failed ($e)\n$st');
    }
  }

  static Future<void> notifyCustomersOfDeal({
    required String titleHe,
    required String titleEn,
    String? bodyHe,
    String? bodyEn,
  }) async {
    if (!SupabaseBootstrap.isReady) return;
    final slug = ManagerStore.instance.linkedBusinessSlug?.trim().toLowerCase();
    if (slug == null || slug.isEmpty) return;

    try {
      await SaasRepository.instance.notifyDealPush(
        businessSlug: slug,
        titleHe: titleHe,
        titleEn: titleEn,
        bodyHe: bodyHe ?? titleHe,
        bodyEn: bodyEn ?? titleEn,
      );
    } catch (e, st) {
      debugPrint('DealPushService: notify failed ($e)\n$st');
    }
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _showLocalNotification(
      title: notification.title ?? (AppLocale.instance.isHebrew ? 'מבצע חדש!' : 'New deal!'),
      body: notification.body ?? '',
    );
  }

  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit),
    );
    await _ensureAndroidChannel();

    final notification = message.notification;
    await _showLocalNotification(
      title: notification?.title ?? 'Bizmi',
      body: notification?.body ?? '',
    );
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _dealChannelId,
        _dealChannelNameHe,
        channelDescription: 'התראות על מבצעים חדשים',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!DefaultFirebaseOptions.isConfigured) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await DealPushService.showBackgroundNotification(message);
}
