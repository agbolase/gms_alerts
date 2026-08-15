import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricGate {
  static const enrolledKey = 'gms_bio_enrolled';
  static const unlockedKey = 'gms_bio_unlocked_at';

  static final LocalAuthentication _auth = LocalAuthentication();
  static bool _busy = false;

  static Future<bool> shouldLock() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(enrolledKey) != true) return false;
    try {
      final supported = await _auth.isDeviceSupported();
      final can = await _auth.canCheckBiometrics;
      if (supported || can) return true;
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setEnrolled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(enrolledKey, value);
  }

  /// Returns true on success. [error] is a user-facing message when false.
  static Future<({bool ok, String? error})> unlock() async {
    if (_busy) {
      return (ok: false, error: null);
    }
    _busy = true;
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) {
        return (ok: false, error: 'This device does not support fingerprint or face unlock.');
      }

      // Face unlock on many Android phones is a "weak" biometric and is
      // blocked when biometricOnly is true. Allow fingerprint, face, and
      // the device PIN/pattern as a fallback so the system prompt can open.
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock GMS with your fingerprint or face',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
      return (ok: ok, error: ok ? null : 'Biometric unlock was cancelled. Tap Unlock to try again.');
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'auth_in_progress':
        case 'AlreadyInProgress':
          return (ok: false, error: null);
        case 'NotAvailable':
        case 'NotEnrolled':
          return (
            ok: false,
            error: 'No fingerprint or face is set up on this phone. Add one in device settings, or use password.',
          );
        case 'LockedOut':
        case 'PermanentlyLockedOut':
          return (ok: false, error: 'Too many attempts. Unlock the phone, then try again.');
        case 'PasscodeNotSet':
          return (ok: false, error: 'Set a screen lock on this phone to enable fingerprint or face unlock.');
        default:
          return (ok: false, error: 'Could not start fingerprint or face unlock. Tap Unlock to try again.');
      }
    } catch (_) {
      return (ok: false, error: 'Could not start fingerprint or face unlock. Tap Unlock to try again.');
    } finally {
      _busy = false;
    }
  }
}
