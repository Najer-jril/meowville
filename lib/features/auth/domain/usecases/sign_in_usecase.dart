import '../entities/auth_user.dart';
import '../entities/login_credentials.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase {
  const SignInUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call({
    required String identifier,
    required String password,
    required bool rememberMe,
  }) {
    final LoginCredentials credentials = LoginCredentials.create(
      identifier: identifier,
      password: password,
      rememberMe: rememberMe,
    );
    return _repository.signIn(credentials);
  }
}
