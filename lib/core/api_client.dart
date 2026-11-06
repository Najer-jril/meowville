import 'dart:convert';

import 'package:http/http.dart' as http;

import 'env.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  String? accessToken;

  Map<String, String> _headers(Map<String, String>? extra) => {
    'apikey': Env.supabaseKey,
    'Content-Type': 'application/json',
    if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    ...?extra,
  };

  Uri _uri(String path) => Uri.parse('${Env.supabaseUrl}$path');

  Future<dynamic> get(String path) async =>
      _decode(await http.get(_uri(path), headers: _headers(null)));

  Future<dynamic> post(
    String path, [
    Object? body,
    Map<String, String>? headers,
  ]) async => _decode(
    await http.post(
      _uri(path),
      headers: _headers(headers),
      body: body == null ? null : jsonEncode(body),
    ),
  );

  Future<dynamic> patch(String path, Object body) async => _decode(
    await http.patch(
      _uri(path),
      headers: _headers({'Prefer': 'return=representation'}),
      body: jsonEncode(body),
    ),
  );

  Future<dynamic> delete(String path) async =>
      _decode(await http.delete(_uri(path), headers: _headers(null)));

  dynamic _decode(http.Response res) {
    final body = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 300) {
      throw ApiException(res.statusCode, _errorMessage(body, res));
    }
    return body;
  }

  String _errorMessage(dynamic body, http.Response res) {
    if (body is Map) {
      for (final key in ['msg', 'error_description', 'message', 'error']) {
        if (body[key] is String) return body[key] as String;
      }
    }
    return 'HTTP ${res.statusCode}';
  }
}
