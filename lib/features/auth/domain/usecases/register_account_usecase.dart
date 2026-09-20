import '../entities/auth_user.dart';
import '../entities/register_account_params.dart';
import '../entities/user_role.dart';
import '../repositories/auth_repository.dart';

abstract interface class RegisterAccountUseCase {
  Future<AuthUser> call({
    required String name,
    required String email,
    required String whatsappNumber,
    required String password,
    required String confirmPassword,
    required bool termsAccepted,
  });
}

base class _RegisterWithRole implements RegisterAccountUseCase {
  const _RegisterWithRole(this._repository, this._role);

  final AuthRepository _repository;
  final UserRole _role;

  @override
  Future<AuthUser> call({
    required String name,
    required String email,
    required String whatsappNumber,
    required String password,
    required String confirmPassword,
    required bool termsAccepted,
  }) {
    final RegisterAccountParams params = RegisterAccountParams.create(
      name: name,
      email: email,
      whatsappNumber: whatsappNumber,
      password: password,
      confirmPassword: confirmPassword,
      termsAccepted: termsAccepted,
      role: _role,
    );
    return _repository.registerAccount(params);
  }
}

final class RegisterOwnerUseCase extends _RegisterWithRole {
  const RegisterOwnerUseCase(AuthRepository repository)
    : super(repository, UserRole.petOwner);
}

final class RegisterSitterUseCase extends _RegisterWithRole {
  const RegisterSitterUseCase(AuthRepository repository)
    : super(repository, UserRole.petSitter);
}
