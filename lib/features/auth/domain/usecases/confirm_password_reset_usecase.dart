import '../entities/auth_user.dart';
import '../entities/email_address.dart';
import '../entities/new_password.dart';
import '../entities/recovery_code.dart';
import '../repositories/auth_repository.dart';

class ConfirmPasswordResetUseCase {
  const ConfirmPasswordResetUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call({
    required String email,
    required String code,
    required String password,
    required String confirmPassword,
  }) {
    final EmailAddress address = EmailAddress.parse(email);
    final RecoveryCode token = RecoveryCode.parse(code);
    final NewPassword newPassword = NewPassword.create(
      password: password,
      confirmation: confirmPassword,
    );
    return _repository.confirmPasswordReset(
      email: address.value,
      token: token.value,
      newPassword: newPassword.value,
    );
  }
}
