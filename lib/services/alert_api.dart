import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AlertApi {
  static const _base = 'https://gms.grannymurray.com/api/gms/mobile';
  static const tokenKey = 'gms_push_token';
  static const sinceKey = 'gms_since_id';

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
