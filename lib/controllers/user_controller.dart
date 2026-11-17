import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'load_state.dart';

class UserController extends ChangeNotifier with LoadState {
  UserController(this._profiles, this._auth);

  final ProfileService _profiles;
  final AuthService _auth;

  List<AppUser> _users = [];

  List<AppUser> get users => _users;

  Future<void> load() => runLoad(() async {
    _users = await _profiles.fetchAll();
  });

  bool emailTaken(String email) =>
      _users.any((u) => u.email.toLowerCase() == email.toLowerCase());

  /// register akun baru. Server selalu membuat akun sebagai owner, jadi role staf diatur belakangan oleh admin lewat RPC.
  Future<void> create({
    required String name,
    required String phone,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final id = await _auth.signUp(
      email: email,
      password: password,
      name: name,
      phone: phone,
    );
    if (role != UserRole.owner) {
      await _profiles.setRole(id, role);
    }
    await load();
  }

  void reset() {
    _users = [];
    notifyListeners();
  }
}
