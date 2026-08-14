import 'package:flutter/material.dart';
import 'app.dart';
import 'background.dart';
import 'services/alert_sound.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AlertSound.init();
  await startBackgroundAlerts();
  runApp(const GmsAlertsApp());
}
