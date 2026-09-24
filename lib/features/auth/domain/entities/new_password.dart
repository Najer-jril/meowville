import '../../../../core/errors/app_exception.dart';

class NewPassword {
  const NewPassword._(this.value);

  static const int minLength = 8;

  factory NewPassword.create({
    required String password,
    required String confirmation,
  }) {
    if (password.length < minLength) {
      throw const ValidationException(
        'Kata sandi minimal $minLength karakter.',
      );
    }
    if (password != confirmation) {
      throw const ValidationException(
        'Konfirmasi kata sandi belum sama dengan kata sandi.',
      );
    }
    return NewPassword._(password);
  }

  final String value;
}
