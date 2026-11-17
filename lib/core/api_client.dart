import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

  /// update sesi setelah dapat 401. return true kalau request layak diulang.
  Future<bool> Function()? onUnauthorized;

  Map<String, String> _headers(Map<String, String>? extra) => {
    'apikey': Env.supabaseKey,
    'Content-Type': 'application/json',
    if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    ...?extra,
  };

  Uri _uri(String path) => Uri.parse('${Env.supabaseUrl}$path');

  Future<dynamic> get(String path) =>
      _send(() => http.get(_uri(path), headers: _headers(null)));

  Future<dynamic> post(
    String path, [
    Object? body,
    Map<String, String>? headers,
  ]) => _send(
    () => http.post(
      _uri(path),
      headers: _headers(headers),
      body: body == null ? null : jsonEncode(body),
    ),
  );

  Future<dynamic> patch(String path, Object body) => _send(
    () => http.patch(
      _uri(path),
      headers: _headers({'Prefer': 'return=representation'}),
      body: jsonEncode(body),
    ),
  );

  Future<dynamic> put(String path, Object body) => _send(
    () => http.put(_uri(path), headers: _headers(null), body: jsonEncode(body)),
  );

  Future<dynamic> delete(String path, [Object? body]) => _send(
    () => http.delete(
      _uri(path),
      headers: _headers(null),
      body: body == null ? null : jsonEncode(body),
    ),
  );

  Future<Map<String, dynamic>> insert(String table, Object row) async {
    final rows = await post('/rest/v1/$table', row, {
      'Prefer': 'return=representation',
    });
    return (rows as List).first as Map<String, dynamic>;
  }

  Future<dynamic> rpc(String fn, [Map<String, dynamic> params = const {}]) =>
      post('/rest/v1/rpc/$fn', params);

  Future<void> upload(
    String bucket,
    String path,
    Uint8List bytes,
    String contentType,
  ) => _send(
    () => http.post(
      _uri('/storage/v1/object/$bucket/$path'),
      headers: _headers({'Content-Type': contentType}),
      body: bytes,
    ),
  );

  String publicUrl(String bucket, String path) =>
      '${Env.supabaseUrl}/storage/v1/object/public/$bucket/$path';

  Future<String> signedUrl(String bucket, String path) async {
    final json = await post('/storage/v1/object/sign/$bucket/$path', {
      'expiresIn': 3600,
    });
    return '${Env.supabaseUrl}/storage/v1${json['signedURL']}';
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      var res = await request();
      if (res.statusCode == 401 &&
          accessToken != null &&
          await (onUnauthorized?.call() ?? Future.value(false))) {
        res = await request();
      }
      return _decode(res);
    } on SocketException {
      throw ApiException(0, 'Tidak ada koneksi internet');
    } on http.ClientException catch (e) {
      if (e.message.contains('Failed host lookup')) {
        throw ApiException(0, 'Tidak ada koneksi internet');
      }
      rethrow;
    }
  }

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
        if (body[key] is String) return _translate(body[key] as String);
      }
    }
    return 'HTTP ${res.statusCode}';
  }

  static String _translate(String message) {
    if (message == 'Invalid login credentials') {
      return 'Email atau kata sandi salah';
    }
    if (message.contains('Email not confirmed')) {
      return 'Email belum diverifikasi. Cek kotak masuk atau folder spam.';
    }
    if (message.contains('User already registered')) {
      return 'Email sudah terdaftar';
    }
    if (message.toLowerCase().contains('rate limit')) {
      return 'Terlalu banyak percobaan. Coba lagi beberapa menit lagi.';
    }
    if (message.contains('room_types_prefix_key')) {
      return 'Prefix sudah dipakai tipe kamar lain';
    }
    if (message.contains('row-level security') &&
        message.contains('daily_reports')) {
      return 'Laporan hanya bisa dibuat untuk kucing yang sedang menginap';
    }
    if (message.contains('Token has expired or is invalid')) {
      return 'Kode salah atau sudah kedaluwarsa';
    }
    if (message.contains('JWT expired')) {
      return 'Sesi berakhir, silakan login ulang';
    }
    return message;
  }
}
