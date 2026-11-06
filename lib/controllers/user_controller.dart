import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

/// Account list for the admin, loaded from GET /rest/v1/profiles.
class UserController extends ChangeNotifier {
  UserController(this._profiles, this._auth);

  final ProfileService _profiles;
  final AuthService _auth;

  List<AppUser> _users = [];
  bool _loading = false;
  String? _error;

  List<AppUser> get users => _users;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _users = await _profiles.fetchAll();
    } on Object catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  bool emailTaken(String email) =>
      _users.any((u) => u.email.toLowerCase() == email.toLowerCase());

  Future<void> create({
    required String name,
    required String phone,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    await _auth.signUp(
      email: email,
      password: password,
      name: name,
      phone: phone,
      role: role,
    );
    await load();
  }
}
