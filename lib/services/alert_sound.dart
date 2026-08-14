import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/models/models.dart';
import 'alert_api.dart';

class AlertSound {
  AlertSound._();

  static final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static Future<void> Function(int id)? onOpened;

  static Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
    );
    await plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (resp) async {
        final id = int.tryParse(resp.payload ?? '') ?? 0;
        if (id > 0) {
          final unread = await AlertApi.markRead([id]);
          await setBadge(unread);
          await onOpened?.call(id);
        }
      },
    );

    const channel = AndroidNotificationChannel(
      'gms_alerts',
      'GMS school alerts',
      description: 'School alerts with sound',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    await plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await Permission.notification.request();
    _ready = true;
  }

  static Future<void> setBadge(int count) async {
    if (count <= 0) {
      await AppBadgePlus.updateBadge(0);
      await plugin.cancelAll();
      return;
    }
    await AppBadgePlus.updateBadge(count);
  }

  static Future<void> play(GmsAlert alert, {int unread = 1}) async {
    await init();
    await setBadge(unread);
    final android = AndroidNotificationDetails(
      'gms_alerts',
      'GMS school alerts',
      channelDescription: 'School alerts with sound',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      number: unread,
      audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
    );
    final ios = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
      badgeNumber: unread,
      sound: 'default',
    );
    await plugin.show(
      alert.id,
      alert.title,
      alert.body,
      NotificationDetails(android: android, iOS: ios),
      payload: '${alert.id}',
    );
  }
}
