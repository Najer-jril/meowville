import '../entities/email_address.dart';
import '../repositories/auth_repository.dart';

class RequestPasswordResetUseCase {
  const RequestPasswordResetUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String email}) {
    final EmailAddress address = EmailAddress.parse(email);
    return _repository.requestPasswordReset(address.value);
  }
}
