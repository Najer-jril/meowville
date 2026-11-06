import '../core/api_client.dart';
import '../core/session.dart';
import '../data/models.dart';

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

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
  }) async {
    await _api.post('/auth/v1/signup', {
      'email': email,
      'password': password,
      'data': {'name': name, 'phone': phone, 'role': role.key},
    });
  }

  Future<void> signOut() => _api.post('/auth/v1/logout');
}
