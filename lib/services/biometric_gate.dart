import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricGate {
  static const enrolledKey = 'gms_bio_enrolled';
  static const unlockedKey = 'gms_bio_unlocked_at';

  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> shouldLock() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(enrolledKey) != true) return false;
    try {
      final supported = await _auth.isDeviceSupported();
      final can = await _auth.canCheckBiometrics;
      return supported && can;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setEnrolled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(enrolledKey, value);
  }

  static Future<bool> unlock() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock GMS with your fingerprint or face',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
