import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meowville/app/routes/app_router.dart';
import 'package:meowville/core/errors/app_exception.dart';
import 'package:meowville/core/widgets/app_primary_button.dart';
import 'package:meowville/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:meowville/features/auth/presentation/screens/login_screen.dart';
import 'package:meowville/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:meowville/features/dashboard/presentation/screens/owner_dashboard_screen.dart';

import 'fake_auth_repository.dart';
import '../../../support/app_harness.dart';

void main() {
  const String email = 'rani@contoh.com';

  group('layar minta kode', () {
    testWidgets('tautan di layar masuk membuka layar minta kode', (
      WidgetTester tester,
    ) async {
      final FakeAuthRepository repository = FakeAuthRepository();
      addTearDown(repository.dispose);
      await pumpApp(tester, repository);

      await tapVisible(tester, find.text('Lupa Kata Sandi?'));

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.text('Kirim Kode ke Email'), findsOneWidget);
    });

    testWidgets('email kosong ditolak sebelum permintaan jaringan', (
      WidgetTester tester,
    ) async {
      final FakeAuthRepository repository = FakeAuthRepository();
      addTearDown(repository.dispose);
      await pumpApp(tester, repository, location: '/lupa-sandi');

      await tapVisible(tester, find.text('Kirim Kode ke Email'));

      expect(repository.requestResetCalls, isEmpty);
      expect(find.text('Alamat email wajib diisi.'), findsOneWidget);
    });

    testWidgets('format email salah ditolak sebelum permintaan jaringan', (
      WidgetTester tester,
    ) async {
      final FakeAuthRepository repository = FakeAuthRepository();
      addTearDown(repository.dispose);
      await pumpApp(tester, repository, location: '/lupa-sandi');

      await enterInField(tester, 0, 'rani@contoh');
      await tapVisible(tester, find.text('Kirim Kode ke Email'));

      expect(repository.requestResetCalls, isEmpty);
      expect(
        find.text('Format email belum benar, contoh nama@contoh.com.'),
        findsOneWidget,
      );
    });

    testWidgets('berhasil membawa email ke layar kode dengan pesan netral', (
      WidgetTester tester,
    ) async {
      final FakeAuthRepository repository = FakeAuthRepository();
      addTearDown(repository.dispose);
      await pumpApp(tester, repository, location: '/lupa-sandi');

      await enterInField(tester, 0, ' Rani@Contoh.com ');
      await tapVisible(tester, find.text('Kirim Kode ke Email'));

      expect(repository.requestResetCalls, <String>[email]);
      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      expect(find.text(email), findsOneWidget);
      expect(
        find.text('Kalau email itu terdaftar, kodenya sudah dikirim.'),
        findsOneWidget,
      );
      expect(find.textContaining('tidak ditemukan'), findsNothing);
      expect(find.textContaining('belum terdaftar'), findsNothing);
    });

    testWidgets('galat jaringan tampil sebagai spanduk', (
      WidgetTester tester,
    ) async {
      final FakeAuthRepository repository = FakeAuthRepository(
        requestResetError: const NetworkException('Tidak ada koneksi.'),
      );
      addTearDown(repository.dispose);
      await pumpApp(tester, repository, location: '/lupa-sandi');

      await enterInField(tester, 0, email);
      await tapVisible(tester, find.text('Kirim Kode ke Email'));

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.text('Tidak ada koneksi.'), findsOneWidget);
    });

    testWidgets('tautan Kembali Masuk menuju layar masuk', (
      WidgetTester tester,
    ) async {
      final FakeAuthRepository repository = FakeAuthRepository();
      addTearDown(repository.dispose);
      await pumpApp(tester, repository, location: '/lupa-sandi');

      await tapVisible(tester, find.text('Kembali Masuk'));

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('tidak ada luapan mendatar pada 320 px', (
      WidgetTester tester,
    ) async {
      final FakeAuthRepository repository = FakeAuthRepository();
      addTearDown(repository.dispose);
      await pumpApp(
        tester,
        repository,
        size: const Size(320, 640),
        location: '/lupa-sandi',
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('layar kode dan kata sandi baru', () {
    Future<void> openWithEmail(
      WidgetTester tester,
      FakeAuthRepository repository, {
      Size size = const Size(393, 852),
    }) async {
      await pumpApp(
        tester,
        repository,
        size: size,
        location: '/atur-ulang-sandi',
        extra: email,
      );
    }

    bool saveEnabled(WidgetTester tester) {
      return tester
              .widget<AppPrimaryButton>(find.byType(AppPrimaryButton))
              .onPressed !=
          null;
    }

    testWidgets('email dari layar pertama tampil sebagai teks, bukan isian', (
      WidgetTester tester,
    ) async {
      final FakeAuthRepository repository = FakeAuthRepository();
      addTearDown(repository.dispose);
      await openWithEmail(tester, repository);

      expect(find.text(email), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3));
    });

    testWidgets('dibuka langsung tanpa email menampilkan isian email', (
      WidgetTester tester,
    ) async {
      final FakeAuthRepository repository = FakeAuthRepository();
      addTearDown(repository.dispose);
      await pumpApp(tester, repository, location: '/atur-ulang-sandi');

      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('kode kurang dari enam angka menonaktifkan tombol simpan', (
      WidgetTester tester,
    ) async {
      final FakeAuthRepository repository = FakeAuthRepository();
      addTearDown(repository.dispose);
      await openWithEmail(tester, repository);

      expect(saveEnabled(tester), isFalse);

      await enterInField(tester, 0, '12345');
      expect(saveEnabled(tester), isFalse);

      await enterInField(tester, 0, '123456');
      expect(saveEnabled(tester), isTrue);
    });

    testWidgets('isian kode hanya menerima angka dan maksimal enam', (
      WidgetTester tester,
    ) async {
      final FakeAuthRepository repository = FakeAuthRepository();
      addTearDown(repository.dispose);
      await openWithEmail(tester, repository);

      await enterInField(tester, 0, '12ab3456789');

      final TextField field = tester.widget<TextField>(
        find.byType(TextField).at(0),
      );
      expect(field.controller!.text, '123456');
    });

    testWidgets('kata sandi di bawah 8 karakter ditolak', (
      WidgetTester tester,
    ) async {
      final FakeAuthRepository repository = FakeAuthRepository();
      addTearDown(repository.dispose);
      await openWithEmail(tester, repository);

      await enterInField(tester, 0, '123456');
      await enterInField(tester, 1, 'pendek');
      await enterInField(tester, 2, 'pendek');
      await tapVisible(tester, find.text('Simpan Kata Sandi Baru'));

      expect(repository.confirmResetCalls, isEmpty);
      expect(find.text('Kata sandi minimal 8 karakter.'), findsOneWidget);
    });

    testWidgets('konfirmasi yang berbeda ditolak', (WidgetTester tester) async {
      final FakeAuthRepository repository = FakeAuthRepository();
      addTearDown(repository.dispose);
      await openWithEmail(tester, repository);

      await enterInField(tester, 0, '123456');
      await enterInField(tester, 1, 'rahasia123');
      await enterInField(tester, 2, 'rahasia124');
      await tapVisible(tester, find.text('Simpan Kata Sandi Baru'));

      expect(repository.confirmResetCalls, isEmpty);
      expect(
        find.text('Konfirmasi kata sandi belum sama dengan kata sandi.'),
        findsOneWidget,
      );
    });

    testWidgets('kode salah menampilkan spanduk galat, bukan layar kosong', (
      WidgetTester tester,
    ) async {
      final FakeAuthRepository repository = FakeAuthRepository(
        confirmResetError: const UnauthorizedException(
          'Kode itu tidak cocok atau sudah lewat satu jam. Minta kode baru.',
        ),
      );
      addTearDown(repository.dispose);
      await openWithEmail(tester, repository);

      await enterInField(tester, 0, '123456');
      await enterInField(tester, 1, 'rahasia123');
      await enterInField(tester, 2, 'rahasia123');
      await tapVisible(tester, find.text('Simpan Kata Sandi Baru'));

      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      expect(
        find.text(
          'Kode itu tidak cocok atau sudah lewat satu jam. Minta kode baru.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Kirim ulang kode mati 60 detik lalu hidup lagi', (
      WidgetTester tester,
    ) async {
      final FakeAuthRepository repository = FakeAuthRepository();
      addTearDown(repository.dispose);
      await openWithEmail(tester, repository);

      expect(find.text('Kirim ulang kode dalam 60 detik'), findsOneWidget);
      expect(find.text('Kirim ulang kode'), findsNothing);

      await tester.pump(const Duration(seconds: 59));
      expect(find.text('Kirim ulang kode dalam 1 detik'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Kirim ulang kode'), findsOneWidget);

      await tapVisible(tester, find.text('Kirim ulang kode'));

      expect(repository.requestResetCalls, <String>[email]);
      expect(find.text('Kirim ulang kode dalam 60 detik'), findsOneWidget);
      expect(
        find.text('Kalau email itu terdaftar, kode baru sudah dikirim.'),
        findsOneWidget,
      );
    });

    testWidgets('tidak ada luapan mendatar pada 320 px', (
      WidgetTester tester,
    ) async {
      final FakeAuthRepository repository = FakeAuthRepository();
      addTearDown(repository.dispose);
      await openWithEmail(tester, repository, size: const Size(320, 640));

      expect(tester.takeException(), isNull);
    });
  });

  group('alur penuh', () {
    testWidgets(
      'verifyOTP membuat sesi, tetapi pengguna baru pindah setelah updateUser',
      (WidgetTester tester) async {
        final FakeAuthRepository repository = FakeAuthRepository();
        addTearDown(repository.dispose);
        await pumpApp(tester, repository);

        await tapVisible(tester, find.text('Lupa Kata Sandi?'));
        await enterInField(tester, 0, email);
        await tapVisible(tester, find.text('Kirim Kode ke Email'));

        await enterInField(tester, 0, '123456');
        await enterInField(tester, 1, 'rahasia123');
        await enterInField(tester, 2, 'rahasia123');

        await tester.ensureVisible(find.text('Simpan Kata Sandi Baru'));
        await settleBriefly(tester);
        await tester.tap(find.text('Simpan Kata Sandi Baru'));
        await tester.pump(const Duration(milliseconds: 5));

        expect(repository.confirmResetCalls.single, (
          email: email,
          token: '123456',
          newPassword: 'rahasia123',
        ));
        expect(find.byType(ResetPasswordScreen), findsOneWidget);
        expect(find.byType(OwnerDashboardScreen), findsNothing);

        await settleBriefly(tester);

        expect(find.byType(OwnerDashboardScreen), findsOneWidget);
        expect(find.text('Kata sandi diperbarui. Anda sudah masuk.'), findsOne);
      },
    );

    testWidgets('layar reset tetap terbuka bagi pengguna yang belum masuk', (
      WidgetTester tester,
    ) async {
      final FakeAuthRepository repository = FakeAuthRepository();
      addTearDown(repository.dispose);
      final AppRouter router = await pumpApp(
        tester,
        repository,
        location: '/atur-ulang-sandi',
        extra: email,
      );

      expect(
        router.router.routeInformationProvider.value.uri.path,
        '/atur-ulang-sandi',
      );
    });
  });
}
