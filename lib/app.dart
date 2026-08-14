import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'features/portal/portal_screen.dart';

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
      home: const PortalScreen(),
    );
  }
}
