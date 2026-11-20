import 'package:flutter_test/flutter_test.dart';
import 'package:meowville/data/models.dart';
import 'package:meowville/widgets/auth_text_field.dart';

void main() {
  group('validateEmail', () {
    test('requires a value', () {
      expect(validateEmail(''), 'Wajib diisi');
      expect(validateEmail('   '), 'Wajib diisi');
    });

    test('rejects malformed addresses', () {
      expect(validateEmail('not-an-email'), 'Format email tidak valid');
      expect(validateEmail('a@b'), 'Format email tidak valid');
    });

    test('accepts a normal address', () {
      expect(validateEmail(' owner@test.local '), isNull);
    });
  });

  test('AppSettings.fromJson reads the settings row', () {
    final s = AppSettings.fromJson({
      'demo_mode': false,
      'bank_name': 'BCA',
      'bank_account': '123',
      'bank_holder': 'Meowville',
      'support_email': 'meowville@najer.dev',
    });
    expect(s.demoMode, isFalse);
    expect(s.bankName, 'BCA');
    expect(s.supportEmail, 'meowville@najer.dev');
  });

  test('AppSettings.fallback is in demo mode', () {
    expect(AppSettings.fallback.demoMode, isTrue);
  });

  test('AppUser.fromJson does not need a phone number', () {
    final u = AppUser.fromJson({
      'id': 'u1',
      'name': 'Najer Pinkman',
      'email': 'najer@test.local',
      'role': 'owner',
      'joined_at': '2026-11-20T00:00:00Z',
      'photo': null,
    });
    expect(u.firstName, 'Najer');
    expect(u.role, UserRole.owner);
  });
}
