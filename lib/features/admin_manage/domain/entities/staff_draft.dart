import '../../../../core/errors/app_exception.dart';
import '../../../auth/domain/entities/email_address.dart';
import '../../../auth/domain/entities/new_password.dart';
import '../../../auth/domain/entities/user_role.dart';
import 'staff_account.dart';

enum StaffField { name, email, password, role }

class StaffDraft {
  const StaffDraft({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  static const int maxNameLength = 100;

  final String name;
  final String email;
  final String password;
  final UserRole? role;

  String get trimmedName => name.trim();

  Map<StaffField, String> validate() {
    final Map<StaffField, String> errors = <StaffField, String>{};

    if (trimmedName.isEmpty) {
      errors[StaffField.name] = 'Nama lengkap wajib diisi.';
    } else if (trimmedName.length > maxNameLength) {
      errors[StaffField.name] = 'Nama maksimal $maxNameLength karakter.';
    }

    try {
      EmailAddress.parse(email);
    } on ValidationException catch (error) {
      errors[StaffField.email] = error.message;
    }

    if (password.length < NewPassword.minLength) {
      errors[StaffField.password] =
          'Kata sandi minimal ${NewPassword.minLength} karakter.';
    }

    if (role == null || !staffRoles.contains(role)) {
      errors[StaffField.role] = 'Pilih hak akses: penjaga atau admin.';
    }
    return errors;
  }
}
