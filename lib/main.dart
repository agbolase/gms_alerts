import 'package:flutter/material.dart';
import 'app.dart';
import 'services/alert_api.dart';
import 'services/alert_sound.dart';
import 'services/fcm_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GmsAlertsApp());
  Future<void>(() async {
    await AlertSound.init();
    if ((await AlertApi.token()).isNotEmpty) {
      await FcmService.start();
    }
  });
}
