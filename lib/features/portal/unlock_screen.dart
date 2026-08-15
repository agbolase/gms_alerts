import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/biometric_gate.dart';
import 'portal_screen.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> with WidgetsBindingObserver {
  String? _error;
  var _prompted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryUnlock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_prompted) {
      _tryUnlock();
    }
  }

  Future<void> _tryUnlock() async {
    if (!mounted) return;
    setState(() => _error = null);
    // The biometric sheet needs a resumed activity; wait one frame + a short delay.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    _prompted = true;
    final result = await BiometricGate.unlock();
    if (!mounted) return;
    if (result.ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PortalScreen()),
      );
      return;
    }
    if (result.error != null) {
      setState(() => _error = result.error);
    }
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
                const Text(
                  'Use fingerprint or face to open GMS',
                  textAlign: TextAlign.center,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    _prompted = false;
                    _tryUnlock();
                  },
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
