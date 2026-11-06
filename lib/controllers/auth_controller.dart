import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/session.dart';
import '../core/session_storage.dart';
import '../data/models.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._api, this._auth, this._profiles, this._storage);

  final ApiClient _api;
  final AuthService _auth;
  final ProfileService _profiles;
  final SessionStorage _storage;

  Session? _session;
  AppUser? _user;
  bool _remembered = false;
  Timer? _refreshTimer;

  Session? get session => _session;
  AppUser? get user => _user;
  bool get remembered => _remembered;

  Future<AppUser?> restore() async {
    final saved = await _storage.load();
    if (saved == null) return null;
    try {
      final session = saved.isExpired
          ? await _auth.refresh(saved.refreshToken)
          : saved;
      return await _start(session, remember: true);
    } on Object {
      await _clear();
      return null;
    }
  }

  Future<AppUser> signIn(
    String email,
    String password, {
    required bool remember,
  }) async {
    final session = await _auth.signIn(email, password);
    try {
      return await _start(session, remember: remember);
    } on Object {
      await _clear();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on Object {
      //
    }
    await _clear();
  }

  Future<AppUser> _start(Session session, {required bool remember}) async {
    _session = session;
    _api.accessToken = session.accessToken;
    _user = await _profiles.fetchById(session.userId);
    _remembered = remember;
    if (remember) {
      await _storage.save(session);
    } else {
      await _storage.clear();
    }
    _scheduleRefresh();
    notifyListeners();
    return _user!;
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    final session = _session;
    if (session == null) return;
    var wait = session.expiresAt
        .subtract(const Duration(minutes: 1))
        .difference(DateTime.now());
    if (wait.isNegative) wait = Duration.zero;
    _refreshTimer = Timer(wait, _refresh);
  }

  Future<void> _refresh() async {
    final current = _session;
    if (current == null) return;
    try {
      final next = await _auth.refresh(current.refreshToken);
      _session = next;
      _api.accessToken = next.accessToken;
      if (_remembered) await _storage.save(next);
      _scheduleRefresh();
      notifyListeners();
    } on Object {
      _refreshTimer = Timer(const Duration(seconds: 30), _refresh);
    }
  }

  Future<void> _clear() async {
    _refreshTimer?.cancel();
    _session = null;
    _user = null;
    _remembered = false;
    _api.accessToken = null;
    await _storage.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
