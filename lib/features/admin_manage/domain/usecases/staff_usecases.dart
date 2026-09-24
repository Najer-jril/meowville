import '../../../../core/errors/app_exception.dart';
import '../../../auth/domain/entities/email_address.dart';
import '../entities/staff_account.dart';
import '../entities/staff_draft.dart';
import '../repositories/admin_staff_repository.dart';

class LoadStaffAccountsUseCase {
  const LoadStaffAccountsUseCase(this._repository);

  final AdminStaffRepository _repository;

  Future<List<StaffAccount>> call() => _repository.loadStaff();
}

class CreateStaffAccountUseCase {
  const CreateStaffAccountUseCase(this._repository);

  final AdminStaffRepository _repository;

  Future<void> call(StaffDraft draft) async {
    final Map<StaffField, String> errors = draft.validate();
    if (errors.isNotEmpty) {
      throw ValidationException(errors.values.first);
    }
    await _repository.createStaff(
      name: draft.trimmedName,
      email: EmailAddress.parse(draft.email).value,
      password: draft.password,
      role: draft.role!,
    );
  }
}
