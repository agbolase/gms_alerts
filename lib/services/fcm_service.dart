import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../core/models/models.dart';
import 'alert_api.dart';
import 'alert_sound.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class FcmService {
  static bool _started = false;

  static Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('FCM init skipped: $e');
      return;
    }

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((msg) async {
      final n = msg.notification;
      final id = int.tryParse('${msg.data['notification_id'] ?? 0}') ?? DateTime.now().millisecondsSinceEpoch % 100000;
      await AlertSound.play(
        GmsAlert(
          id: id,
          type: '${msg.data['type'] ?? 'alert'}',
          title: n?.title ?? 'GMS',
          body: n?.body ?? '',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
    });

    await _sendToken(await messaging.getToken());
    messaging.onTokenRefresh.listen(_sendToken);
  }

  static Future<void> _sendToken(String? fcm) async {
    if (fcm == null || fcm.isEmpty) return;
    final appToken = await AlertApi.token();
    if (appToken.isEmpty) return;
    try {
      await AlertApi.registerFcm(appToken, fcm, Platform.isIOS ? 'ios' : 'android');
    } catch (e) {
      debugPrint('FCM register failed: $e');
    }
  }
}
