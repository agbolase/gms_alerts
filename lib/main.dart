import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/storage/token_storage.dart';
import 'providers/auth_state.dart';
import 'services/alert_sound.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AlertSound.init();
  final authService = AuthService(TokenStorage());
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthState(authService)..bootstrap(),
      child: const GmsAlertsApp(),
    ),
  );
}
