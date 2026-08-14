import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthState extends ChangeNotifier {
  AuthState(this._auth);

  final AuthService _auth;
  bool loading = true;
  String? error;

  bool get isLoggedIn => _auth.user != null;
  AuthService get auth => _auth;

  Future<void> bootstrap() async {
    loading = true;
    notifyListeners();
    try {
      await _auth.restoreSession();
    } catch (_) {
      await _auth.logout();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    error = null;
    loading = true;
    notifyListeners();
    try {
      await _auth.login(username, password);
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    notifyListeners();
  }
}
