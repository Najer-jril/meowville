import '../../../../core/errors/app_exception.dart';
import 'new_password.dart';
import 'user_role.dart';
import 'whatsapp_number.dart';

class RegisterAccountParams {
  const RegisterAccountParams._({
    required this.name,
    required this.email,
    required this.whatsappNumber,
    required this.password,
    required this.role,
  });

  factory RegisterAccountParams.create({
    required String name,
    required String email,
    required String whatsappNumber,
    required String password,
    required String confirmPassword,
    required bool termsAccepted,
    required UserRole role,
  }) {
    final String trimmedName = name.trim();
    final String trimmedEmail = email.trim().toLowerCase();

    if (trimmedName.isEmpty) {
      throw const ValidationException('Nama lengkap wajib diisi.');
    }
    if (trimmedName.length > 100) {
      throw const ValidationException('Nama lengkap maksimal 100 karakter.');
    }
    if (trimmedEmail.isEmpty) {
      throw const ValidationException('Alamat email wajib diisi.');
    }
    if (!_emailPattern.hasMatch(trimmedEmail)) {
      throw const ValidationException(
        'Format email belum benar, contoh nama@contoh.com.',
      );
    }
    if (trimmedEmail.length > 150) {
      throw const ValidationException('Alamat email maksimal 150 karakter.');
    }
    final NewPassword newPassword = NewPassword.create(
      password: password,
      confirmation: confirmPassword,
    );
    if (!termsAccepted) {
      throw const ValidationException(
        'Centang persetujuan ketentuan layanan untuk melanjutkan.',
      );
    }

    final WhatsAppNumber number = WhatsAppNumber.parse(whatsappNumber);

    return RegisterAccountParams._(
      name: trimmedName,
      email: trimmedEmail,
      whatsappNumber: number.value,
      password: newPassword.value,
      role: role,
    );
  }

  static final RegExp _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  final String name;
  final String email;
  final String whatsappNumber;
  final String password;
  final UserRole role;
}
