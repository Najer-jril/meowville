import '../../../../core/errors/app_exception.dart';

extension type const EmailAddress._(String value) {
  factory EmailAddress.parse(String raw) {
    final String trimmed = raw.trim().toLowerCase();

    if (trimmed.isEmpty) {
      throw const ValidationException('Alamat email wajib diisi.');
    }
    if (!_pattern.hasMatch(trimmed)) {
      throw const ValidationException(
        'Format email belum benar, contoh nama@contoh.com.',
      );
    }
    return EmailAddress._(trimmed);
  }

  static final RegExp _pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
}
