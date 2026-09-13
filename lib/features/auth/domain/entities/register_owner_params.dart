import '../../../../core/errors/app_exception.dart';
import 'whatsapp_number.dart';

class RegisterOwnerParams {
  const RegisterOwnerParams._({
    required this.name,
    required this.email,
    required this.whatsappNumber,
    required this.password,
  });

  static const int minPasswordLength = 8;

  factory RegisterOwnerParams.create({
    required String name,
    required String email,
    required String whatsappNumber,
    required String password,
    required String confirmPassword,
    required bool termsAccepted,
  }) {
    final String trimmedName = name.trim();
    final String trimmedEmail = email.trim().toLowerCase();

    if (trimmedName.isEmpty) {
      throw const ValidationException('Nama lengkap pemilik wajib diisi.');
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
    if (password.length < minPasswordLength) {
      throw const ValidationException(
        'Kata sandi minimal $minPasswordLength karakter.',
      );
    }
    if (password != confirmPassword) {
      throw const ValidationException(
        'Konfirmasi kata sandi belum sama dengan kata sandi.',
      );
    }
    if (!termsAccepted) {
      throw const ValidationException(
        'Centang persetujuan ketentuan layanan untuk melanjutkan.',
      );
    }

    final WhatsAppNumber number = WhatsAppNumber.parse(whatsappNumber);

    return RegisterOwnerParams._(
      name: trimmedName,
      email: trimmedEmail,
      whatsappNumber: number.value,
      password: password,
    );
  }

  static final RegExp _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  final String name;
  final String email;
  final String whatsappNumber;
  final String password;
}
