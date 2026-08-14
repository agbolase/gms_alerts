import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';

class ApiClient {
  ApiClient({this.token});

  String? token;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final clean = path.replaceAll(RegExp(r'^/+'), '');
    return Uri.parse('$base/$clean').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) async {
    final res = await http
        .get(_uri(path, query), headers: _headers)
        .timeout(AppConfig.requestTimeout);
    return _decode(res);
  }

  Future<Map<String, dynamic>> poll(String path, {Map<String, String>? query}) async {
    final res = await http
        .get(_uri(path, query), headers: _headers)
        .timeout(AppConfig.pollTimeout);
    return _decode(res);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> fields) async {
    final res = await http
        .post(_uri(path), headers: _headers, body: jsonEncode(fields))
        .timeout(AppConfig.requestTimeout);
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    final body = res.body.isEmpty ? '{}' : res.body;
    final data = jsonDecode(body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw ApiException(
        data['message'] as String? ?? 'Request failed (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    return data;
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
