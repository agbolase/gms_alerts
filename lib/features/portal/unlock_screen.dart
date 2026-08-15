import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/biometric_gate.dart';
import 'portal_screen.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryUnlock());
  }

  Future<void> _tryUnlock() async {
    final ok = await BiometricGate.unlock();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PortalScreen()),
      );
      return;
    }
    setState(() => _error = 'Biometric unlock failed. Try again.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/app_icon.png', width: 88, height: 88),
                const SizedBox(height: 16),
                Text(AppConfig.appName, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('Use fingerprint or face to open GMS'),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _tryUnlock,
                  child: const Text('Unlock'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const PortalScreen()),
                    );
                  },
                  child: const Text('Use password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
