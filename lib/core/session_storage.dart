import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'session.dart';

/// Keeps the session on the device so "Ingat saya" survives an app restart.
class SessionStorage {
  static const _key = 'meowville.session';

  Future<Session?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      await prefs.remove(_key);
      return null;
    }
  }

  Future<void> save(Session session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
