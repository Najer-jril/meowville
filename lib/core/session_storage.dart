import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'session.dart';

class SessionStorage {
  static const _key = 'meowville.session';
  static const _secure = FlutterSecureStorage();

  Future<Session?> load() async {
    final raw = await _readRaw();
    if (raw == null) return null;
    try {
      return Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      await clear();
      return null;
    }
  }

  Future<void> save(Session session) =>
      _secure.write(key: _key, value: jsonEncode(session.toJson()));

  Future<void> clear() async {
    await _secure.delete(key: _key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<String?> _readRaw() async {
    final stored = await _secure.read(key: _key);
    if (stored != null) return stored;
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_key);
    if (legacy == null) return null;
    await _secure.write(key: _key, value: legacy);
    await prefs.remove(_key);
    return legacy;
  }
}
