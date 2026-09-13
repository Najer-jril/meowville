import '../entities/auth_user.dart';
import '../entities/register_owner_params.dart';
import '../repositories/auth_repository.dart';

class RegisterOwnerUseCase {
  const RegisterOwnerUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call({
    required String name,
    required String email,
    required String whatsappNumber,
    required String password,
    required String confirmPassword,
    required bool termsAccepted,
  }) {
    final RegisterOwnerParams params = RegisterOwnerParams.create(
      name: name,
      email: email,
      whatsappNumber: whatsappNumber,
      password: password,
      confirmPassword: confirmPassword,
      termsAccepted: termsAccepted,
    );
    return _repository.registerOwner(params);
  }
}
