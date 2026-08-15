import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'features/portal/portal_screen.dart';
import 'features/portal/unlock_screen.dart';
import 'services/biometric_gate.dart';

class GmsAlertsApp extends StatelessWidget {
  const GmsAlertsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A335E)),
        useMaterial3: true,
      ),
      home: const _LaunchGate(),
    );
  }
}

class _LaunchGate extends StatelessWidget {
  const _LaunchGate();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: BiometricGate.shouldLock(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        if (snap.data == true) return const UnlockScreen();
        return const PortalScreen();
      },
    );
  }
}
