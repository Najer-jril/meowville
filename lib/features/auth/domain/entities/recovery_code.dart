import '../../../../core/errors/app_exception.dart';

extension type const RecoveryCode._(String value) {
  static const int length = 6;

  factory RecoveryCode.parse(String raw) {
    final String trimmed = raw.trim();

    if (!_pattern.hasMatch(trimmed)) {
      throw const ValidationException('Kode pemulihan terdiri dari 6 angka.');
    }
    return RecoveryCode._(trimmed);
  }

  static final RegExp _pattern = RegExp(r'^\d{6}$');
}
