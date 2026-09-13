import '../../../../core/errors/app_exception.dart';
import 'whatsapp_number.dart';

class LoginCredentials {
  const LoginCredentials._({
    required this.password,
    required this.rememberMe,
    this.email,
    this.whatsappNumber,
  });

  factory LoginCredentials.create({
    required String identifier,
    required String password,
    required bool rememberMe,
  }) {
    final String trimmed = identifier.trim();

    if (trimmed.isEmpty) {
      throw const ValidationException('Email atau nomor WhatsApp wajib diisi.');
    }
    if (password.isEmpty) {
      throw const ValidationException('Kata sandi wajib diisi.');
    }

    if (trimmed.contains('@')) {
      if (!_emailPattern.hasMatch(trimmed)) {
        throw const ValidationException(
          'Format email belum benar, contoh nama@contoh.com.',
        );
      }
      return LoginCredentials._(
        email: trimmed.toLowerCase(),
        password: password,
        rememberMe: rememberMe,
      );
    }

    final WhatsAppNumber? number = WhatsAppNumber.tryParse(trimmed);
    if (number == null) {
      throw const ValidationException(
        'Masukkan email yang benar, atau nomor WhatsApp 10 sampai 15 angka.',
      );
    }

    return LoginCredentials._(
      whatsappNumber: number.value,
      password: password,
      rememberMe: rememberMe,
    );
  }

  static final RegExp _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  final String? email;
  final String? whatsappNumber;
  final String password;
  final bool rememberMe;

  bool get usesEmail => email != null;
}
