import 'package:flutter_test/flutter_test.dart';
import 'package:meowville/core/errors/app_exception.dart';
import 'package:meowville/features/auth/domain/entities/login_credentials.dart';
import 'package:meowville/features/auth/domain/entities/register_account_params.dart';
import 'package:meowville/features/auth/domain/entities/user_role.dart';
import 'package:meowville/features/auth/domain/entities/whatsapp_number.dart';

void main() {
  group('WhatsAppNumber', () {
    test('membakukan awalan +62 menjadi 0', () {
      expect(WhatsAppNumber.parse('+62 812-3456-7890').value, '081234567890');
    });

    test('membakukan awalan 62 menjadi 0', () {
      expect(WhatsAppNumber.parse('6281234567890').value, '081234567890');
    });

    test('mempertahankan awalan 0', () {
      expect(WhatsAppNumber.parse('0812 3456 7890').value, '081234567890');
    });

    test('menolak nomor yang terlalu pendek', () {
      expect(
        () => WhatsAppNumber.parse('0812'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('tryParse mengembalikan null, bukan melempar', () {
      expect(WhatsAppNumber.tryParse('0812'), isNull);
    });
  });

  group('LoginCredentials', () {
    test('mengenali email', () {
      final LoginCredentials credentials = LoginCredentials.create(
        identifier: '  Rani@Contoh.com ',
        password: 'rahasia123',
        rememberMe: true,
      );

      expect(credentials.usesEmail, isTrue);
      expect(credentials.email, 'rani@contoh.com');
      expect(credentials.whatsappNumber, isNull);
      expect(credentials.rememberMe, isTrue);
    });

    test('mengenali nomor WhatsApp dan membakukannya', () {
      final LoginCredentials credentials = LoginCredentials.create(
        identifier: '+6281234567890',
        password: 'rahasia123',
        rememberMe: false,
      );

      expect(credentials.usesEmail, isFalse);
      expect(credentials.whatsappNumber, '081234567890');
    });

    test('menolak identifier kosong', () {
      expect(
        () => LoginCredentials.create(
          identifier: '   ',
          password: 'rahasia123',
          rememberMe: false,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('menolak kata sandi kosong', () {
      expect(
        () => LoginCredentials.create(
          identifier: 'rani@contoh.com',
          password: '',
          rememberMe: false,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('menolak email yang formatnya salah', () {
      expect(
        () => LoginCredentials.create(
          identifier: 'rani@contoh',
          password: 'rahasia123',
          rememberMe: false,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('RegisterAccountParams', () {
    RegisterAccountParams build({
      String name = 'Rani Pratama',
      String email = 'rani@contoh.com',
      String whatsappNumber = '081234567890',
      String password = 'rahasia123',
      String? confirmPassword,
      bool termsAccepted = true,
      UserRole role = UserRole.petOwner,
    }) {
      return RegisterAccountParams.create(
        name: name,
        email: email,
        whatsappNumber: whatsappNumber,
        password: password,
        confirmPassword: confirmPassword ?? password,
        termsAccepted: termsAccepted,
        role: role,
      );
    }

    test('memangkas nama dan menurunkan huruf email', () {
      final RegisterAccountParams params = build(
        name: '  Rani Pratama  ',
        email: 'Rani@Contoh.com',
      );

      expect(params.name, 'Rani Pratama');
      expect(params.email, 'rani@contoh.com');
      expect(params.whatsappNumber, '081234567890');
    });

    test('menolak kata sandi di bawah 8 karakter', () {
      expect(
        () => build(password: 'rahasia'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('menolak persetujuan yang belum dicentang', () {
      expect(
        () => build(termsAccepted: false),
        throwsA(isA<ValidationException>()),
      );
    });

    test('menolak nama kosong', () {
      expect(() => build(name: '  '), throwsA(isA<ValidationException>()));
    });

    test('menolak nomor WhatsApp yang tidak sah', () {
      expect(
        () => build(whatsappNumber: '12'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('menolak konfirmasi kata sandi yang berbeda', () {
      expect(
        () => build(confirmPassword: 'rahasia124'),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
