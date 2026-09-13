import '../../../../core/errors/app_exception.dart';

extension type const WhatsAppNumber._(String value) {
  factory WhatsAppNumber.parse(String raw) {
    final String digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    String normalized = digits;

    if (normalized.startsWith('+62')) {
      normalized = '0${normalized.substring(3)}';
    } else if (normalized.startsWith('62')) {
      normalized = '0${normalized.substring(2)}';
    }

    normalized = normalized.replaceAll(RegExp(r'[^0-9]'), '');

    if (!normalized.startsWith('0')) {
      normalized = '0$normalized';
    }

    if (normalized.length < 12 || normalized.length > 13) {
      throw const ValidationException(
        'Nomor WhatsApp harus 12 sampai 13 karakter, contoh 089608960896.',
      );
    }

    return WhatsAppNumber._(normalized);
  }

  static WhatsAppNumber? tryParse(String raw) {
    try {
      return WhatsAppNumber.parse(raw);
    } on ValidationException {
      return null;
    }
  }
}
