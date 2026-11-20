import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/session.dart';
import '../core/session_storage.dart';
import '../data/models.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_photo.dart';

class AuthController extends ChangeNotifier {
  AuthController(
    this._api,
    this._auth,
    this._profiles,
    this._storage,
    this._files,
  ) {
    _api.onUnauthorized = refreshNow;
    _api.onSessionExpired = expire;
  }

  final ApiClient _api;
  final AuthService _auth;
  final ProfileService _profiles;
  final SessionStorage _storage;
  final StorageService _files;

  Session? _session;
  AppUser? _user;
  bool _remembered = false;
  Timer? _refreshTimer;
  Future<bool>? _refreshing;

  /// dipanggil saat sesi tidak bisa diperpanjang,, diatur di main.dart untuk membersihkan data layar dan kembali ke login
  VoidCallback? onExpired;

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
    } on ApiException catch (e) {
      // offline,, simpan sesi supaya bisa dipulihkan saat online lagi.
      if (e.statusCode == 0) {
        _session = null;
        _api.accessToken = null;
        return null;
      }
      await _clear();
      return null;
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
      // gagal logout di server diabaikan, data lokal tetap dibersihkan
    }
    await _clear();
  }

  Future<void> updateProfile({
    required String name,
    String? photo,
  }) async {
    final id = _user?.id;
    if (id == null) throw ApiException(401, 'Sesi berakhir, silakan login ulang');
    final url = isLocalPhoto(photo)
        ? await _files.upload(Buckets.avatars, id, photo!)
        : photo;
    _user = await _profiles.update(
      id,
      name: name,
      photo: url,
    );
    notifyListeners();
  }

  Future<void> sendResetCode(String email) => _auth.recover(email);

  Future<void> resetPassword(String email, String code, String password) async {
    final temp = await _auth.verifyRecovery(email, code);
    _api.accessToken = temp.accessToken;
    try {
      await _auth.updatePassword(password);
      await _auth.signOut();
    } finally {
      _api.accessToken = _session?.accessToken;
    }
  }

  Future<void> deleteAccount() async {
    await _profiles.deleteMe();
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
    if (_session == null) return;
    if (await refreshNow()) {
      notifyListeners();
    } else if (_session != null) {
      // gagal karena jaringan,, refresh token yang ditolak sudah memanggil expire()
      _refreshTimer = Timer(const Duration(seconds: 30), _refresh);
    }
  }

  /// satu refresh berjalan pada satu waktu; pemanggil lain menunggu hasil yang sama.
  Future<bool> refreshNow() {
    final pending = _refreshing;
    if (pending != null) return pending;
    final future = _doRefresh();
    _refreshing = future;
    future.whenComplete(() {
      if (identical(_refreshing, future)) _refreshing = null;
    });
    return future;
  }

  Future<bool> _doRefresh() async {
    final current = _session;
    if (current == null) return false;
    try {
      final next = await _auth.refresh(current.refreshToken);
      // logout atau login ulang terjadi selama refresh,, hasilnya dibuang.
      if (!identical(_session, current)) return false;
      _session = next;
      _api.accessToken = next.accessToken;
      if (_remembered) await _storage.save(next);
      _scheduleRefresh();
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 400 || e.statusCode == 401) {
        if (identical(_session, current)) await expire();
      }
      return false;
    } on Object {
      return false;
    }
  }

  /// sesi berakhir (refresh token ditolak atau dicabut)
  Future<void> expire() async {
    if (_session == null) return;
    await _clear();
    onExpired?.call();
  }

  Future<void> _clear() async {
    _refreshTimer?.cancel();
    _session = null;
    _user = null;
    _remembered = false;
    _api.accessToken = null;
    _files.clearCache();
    await _storage.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
