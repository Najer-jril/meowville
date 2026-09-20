import '../entities/auth_user.dart';
import '../entities/login_credentials.dart';
import '../entities/register_account_params.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> get authStateChanges;

  Future<AuthUser?> currentUser();

  Future<AuthUser> signIn(LoginCredentials credentials);

  Future<AuthUser> registerAccount(RegisterAccountParams params);

  Future<void> signOut();
}
