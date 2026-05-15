import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_service.dart';
import '../providers/supabase_provider.dart';

const _androidChannel = AndroidNotificationChannel(
  'forum_notifications',
  'Foro',
  description: 'Notificaciones de actividad del foro.',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

final pushMessagingServiceProvider = Provider<PushMessagingService>((ref) {
  return PushMessagingService(ref);
});

class PushMessagingService {
  PushMessagingService(this._ref);

  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _requestPermission();
    await _configureLocalNotifications();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    _messaging.onTokenRefresh.listen((token) {
      _ref.read(notificationServiceProvider).registerPushToken(
            token,
            platform: defaultTargetPlatform.name,
          );
    });
  }

  Future<void> syncTokenForCurrentUser() async {
    final user = _ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null) return;

    await _requestPermission();
    final token = await _messaging.getToken();
    if (token == null || token.trim().isEmpty) return;

    await _ref.read(notificationServiceProvider).registerPushToken(
          token,
          platform: defaultTargetPlatform.name,
        );
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _configureLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(settings: initializationSettings);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = notification?.android;

    if (notification == null || android == null) return;

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: android.smallIcon,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data['route']?.toString(),
    );
  }
}
