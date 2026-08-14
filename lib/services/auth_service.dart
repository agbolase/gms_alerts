import 'dart:io';
import '../core/api/api_client.dart';
import '../core/models/models.dart';
import '../core/storage/token_storage.dart';

class AuthService {
  AuthService(this._storage);

  final TokenStorage _storage;
  final ApiClient _client = ApiClient();
  GmsUser? user;

  ApiClient get client => _client;

  Future<void> restoreSession() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return;
    _client.token = token;
    final data = await _client.get('me');
    user = GmsUser.fromJson(data['user'] as Map<String, dynamic>);
    await registerDevice();
  }

  Future<void> login(String username, String password) async {
    final data = await _client.post('login', {
      'username': username,
      'password': password,
    });
    final token = data['token'] as String;
    await _storage.saveToken(token);
    _client.token = token;
    user = GmsUser.fromJson(data['user'] as Map<String, dynamic>);
    await registerDevice();
  }

  Future<void> registerDevice() async {
    try {
      await _client.post('register_device', {
        'platform': Platform.isIOS ? 'ios' : 'android',
        'fcm_token': '',
      });
    } catch (_) {}
  }

  Future<void> logout() async {
    try {
      await _client.post('logout', {});
    } catch (_) {}
    user = null;
    _client.token = null;
    await _storage.clear();
  }
}
