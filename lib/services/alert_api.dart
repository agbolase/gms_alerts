import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AlertApi {
  static const _base = 'https://gms.grannymurray.com/api/gms/mobile';
  static const tokenKey = 'gms_push_token';
  static const sinceKey = 'gms_since_id';
  static const shownKeysKey = 'gms_shown_event_keys';
  static const lastUserIdKey = 'gms_last_user_id';

  static Future<void> saveToken(String token) async {
    if (token.isEmpty) return;
    final p = await SharedPreferences.getInstance();
    await p.setString(tokenKey, token);
  }

  static Future<String> token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(tokenKey) ?? '';
  }

  static Future<int> sinceId() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(sinceKey) ?? 0;
  }

  static Future<void> setSinceId(int id) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(sinceKey, id);
  }

  static Future<bool> wasShown(String key) async {
    if (key.isEmpty) return false;
    final p = await SharedPreferences.getInstance();
    final keys = p.getStringList(shownKeysKey) ?? [];
    return keys.contains(key);
  }

  static Future<void> markShown(String key) async {
    if (key.isEmpty) return;
    final p = await SharedPreferences.getInstance();
    final keys = p.getStringList(shownKeysKey) ?? [];
    if (keys.contains(key)) return;
    keys.add(key);
    if (keys.length > 400) {
      keys.removeRange(0, keys.length - 400);
    }
    await p.setStringList(shownKeysKey, keys);
  }

  static Future<void> saveLastUserId(int id) async {
    if (id <= 0) return;
    final p = await SharedPreferences.getInstance();
    await p.setInt(lastUserIdKey, id);
  }

  static Future<int> lastUserId() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(lastUserIdKey) ?? 0;
  }

  static Future<Map<String, dynamic>> faceLogin(List<int> jpeg, {int userId = 0}) async {
    final payload = jsonEncode({
      'face': base64Encode(jpeg),
      if (userId > 0) 'user_id': userId,
    });
    Object? lastError;
    for (final path in const ['face_login', 'face_login.html']) {
      try {
        final res = await http
            .post(
              Uri.parse('$_base/$path'),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: payload,
            )
            .timeout(const Duration(seconds: 45));
        final data = _decode(res);
        if (data['success'] == true || (data['message'] != null && '${data['message']}'.isNotEmpty)) {
          return data;
        }
        lastError = data['message'] ?? 'HTTP ${res.statusCode}';
      } catch (e) {
        lastError = e;
      }
    }
    return {
      'success': false,
      'message': 'Could not reach the school server (${lastError ?? 'unknown'}). Check your connection and try again.',
    };
  }

  static Uri _u(String path, [Map<String, String>? q]) {
    return Uri.parse('$_base/$path').replace(queryParameters: q);
  }

  static Future<Map<String, dynamic>> poll({required String token, required int sinceId}) async {
    final res = await http
        .get(_u('poll_token', {'token': token, 'since_id': '$sinceId'}), headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));
    return _decode(res);
  }

  static Future<void> registerFcm(String appToken, String fcmToken, String platform) async {
    await http
        .post(
          _u('register_device', {'token': appToken}),
          headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
          body: jsonEncode({
            'token': appToken,
            'fcm_token': fcmToken,
            'platform': platform,
          }),
        )
        .timeout(const Duration(seconds: 20));
  }

  static Future<int> markRead(List<int> ids) async {
    final t = await token();
    if (t.isEmpty) return 0;
    final res = await http
        .post(
          _u('mark_read', {'token': t}),
          headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
          body: jsonEncode({'ids': ids, 'token': t}),
        )
        .timeout(const Duration(seconds: 20));
    final data = _decode(res);
    return int.tryParse('${data['unread_count'] ?? 0}') ?? 0;
  }

  static Map<String, dynamic> _decode(http.Response res) {
    final body = res.body.trimLeft();
    if (body.startsWith('<')) return {'success': false, 'data': []};
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
