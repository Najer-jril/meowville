import '../core/api_client.dart';
import '../core/session.dart';

class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  Future<Session> signIn(String email, String password) async {
    final json = await _api.post('/auth/v1/token?grant_type=password', {
      'email': email,
      'password': password,
    });
    return Session.fromAuthJson(json as Map<String, dynamic>);
  }

  Future<Session> refresh(String refreshToken) async {
    final json = await _api.post('/auth/v1/token?grant_type=refresh_token', {
      'refresh_token': refreshToken,
    });
    return Session.fromAuthJson(json as Map<String, dynamic>);
  }

  /// return id user baru. Server selalu membuat profil owner
  Future<String> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final json = await _api.post('/auth/v1/signup', {
      'email': email,
      'password': password,
      'data': {'name': name},
    });
    // if "Confirm email" aktif, response-nya berupa user itu sendiri
    final user = (json as Map<String, dynamic>)['user'] ?? json;
    return (user as Map<String, dynamic>)['id'] as String;
  }

  /// send kode pemulihan 6 digit ke email
  Future<void> recover(String email) =>
      _api.post('/auth/v1/recover', {'email': email});

  Future<Session> verifyRecovery(String email, String token) async {
    final json = await _api.post('/auth/v1/verify', {
      'type': 'recovery',
      'email': email,
      'token': token,
    });
    return Session.fromAuthJson(json as Map<String, dynamic>);
  }

  /// perlu access token dari [verifyRecovery] atau sesi biasa
  Future<void> updatePassword(String password) =>
      _api.put('/auth/v1/user', {'password': password});

  Future<void> signOut() => _api.post('/auth/v1/logout');
}
