import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/models/models.dart';

class AlertSound {
  AlertSound._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    const channel = AndroidNotificationChannel(
      'gms_alerts',
      'GMS school alerts',
      description: 'Invoices, exams, assignments, classes, and attendance',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await Permission.notification.request();
    _ready = true;
  }

  static Future<void> play(GmsAlert alert) async {
    await init();
    const android = AndroidNotificationDetails(
      'gms_alerts',
      'GMS school alerts',
      channelDescription: 'School alerts with sound',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
      sound: 'default',
    );
    await _plugin.show(
      alert.id,
      alert.title,
      alert.body,
      const NotificationDetails(android: android, iOS: ios),
    );
  }
}
