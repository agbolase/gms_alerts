import 'package:flutter/material.dart';
import 'app.dart';
import 'services/alert_sound.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AlertSound.init();
  runApp(const GmsAlertsApp());
}
