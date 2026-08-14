import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/home/home_screen.dart';
import 'providers/auth_state.dart';

class GmsAlertsApp extends StatelessWidget {
  const GmsAlertsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GMS Alerts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      home: Consumer<AuthState>(
        builder: (context, auth, _) {
          if (auth.loading) return const SplashScreen();
          if (!auth.isLoggedIn) return const LoginScreen();
          return const HomeScreen();
        },
      ),
    );
  }
}
