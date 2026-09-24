import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meowville/core/errors/app_exception.dart';
import 'package:meowville/features/admin_manage/domain/entities/staff_account.dart';
import 'package:meowville/features/admin_manage/presentation/widgets/staff_widgets.dart';
import 'package:meowville/features/auth/domain/entities/user_role.dart';

import '../../support/app_harness.dart';
import '../auth/presentation/fake_auth_repository.dart';
import 'fake_admin_staff_repository.dart';

void main() {
  const String hubRoute = '/admin/kelola';
  const String staffRoute = '/admin/kelola/staf';
  const String createRoute = '/admin/kelola/staf/baru';

  final List<StaffAccount> accounts = <StaffAccount>[
    staffAccount(),
    staffAccount(
      id: '00000000-0000-4000-8000-000000000102',
      name: 'Bagus Santoso',
      email: 'bagus@contoh.com',
      role: UserRole.admin,
    ),
  ];

  Future<FakeAdminStaffRepository> open(
    WidgetTester tester, {
    required String location,
    FakeAdminStaffRepository? repository,
    Size size = const Size(393, 852),
  }) async {
    final FakeAuthRepository auth = FakeAuthRepository(
      initialUser: userWithRole(UserRole.admin),
    );
    addTearDown(auth.dispose);
    final FakeAdminStaffRepository staff =
        repository ?? FakeAdminStaffRepository(accounts: accounts);
    await pumpApp(
      tester,
      auth,
      adminStaffRepository: staff,
      location: location,
      size: size,
    );
    await tester.pumpAndSettle();
    return staff;
  }

  group('hub Kelola', () {
    testWidgets('menampilkan akun yang masuk dan menu', (tester) async {
      await open(tester, location: hubRoute);

      expect(find.text('Rani Pratama'), findsOneWidget);
      expect(find.text('rani@contoh.com'), findsOneWidget);
      expect(find.text('Akun staf'), findsOneWidget);
      // Tujuan yang belum dibangun diberi label, bukan menyamar jadi fitur.
      expect(find.text('Belum dibangun'), findsNWidgets(2));
    });

    testWidgets('Akun staf membuka daftar staf', (tester) async {
      await open(tester, location: hubRoute);

      await tapVisible(tester, find.text('Akun staf'));
      await tester.pumpAndSettle();

      expect(find.text('Dinda Kirana'), findsOneWidget);
    });

    testWidgets('Layanan add-on membuka layar belum dibangun', (tester) async {
      await open(tester, location: hubRoute);

      await tapVisible(tester, find.text('Layanan add-on'));
      await tester.pumpAndSettle();

      expect(find.text('Belum dibangun'), findsOneWidget);
      await tapVisible(tester, find.text('Kelola').first);
      await tester.pumpAndSettle();
      expect(find.text('Laporan hotel'), findsOneWidget);
    });
  });

  group('daftar akun staf', () {
    testWidgets('keadaan memuat menyebut apa yang dimuat', (tester) async {
      final Completer<void> gate = Completer<void>();
      final FakeAuthRepository auth = FakeAuthRepository(
        initialUser: userWithRole(UserRole.admin),
      );
      addTearDown(auth.dispose);
      await pumpApp(
        tester,
        auth,
        adminStaffRepository: FakeAdminStaffRepository(gate: gate.future),
        location: staffRoute,
      );

      expect(find.text('Memuat akun staf...'), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('galat bisa dicoba ulang', (tester) async {
      final FakeAdminStaffRepository repository = FakeAdminStaffRepository(
        accounts: accounts,
        loadError: const NetworkException('Tidak ada koneksi.'),
      );
      await open(tester, location: staffRoute, repository: repository);

      expect(find.text('Akun staf belum bisa dimuat'), findsOneWidget);
      repository.loadError = null;
      await tapVisible(tester, find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(find.text('Dinda Kirana'), findsOneWidget);
    });

    testWidgets('saring per peran', (tester) async {
      await open(tester, location: staffRoute);

      expect(find.byType(StaffAccountCard), findsNWidgets(2));
      await tapVisible(tester, find.text('Admin').first);

      expect(find.byType(StaffAccountCard), findsOneWidget);
      expect(find.text('Bagus Santoso'), findsOneWidget);
    });

    testWidgets('peran tanpa akun punya keadaan kosong', (tester) async {
      await open(
        tester,
        location: staffRoute,
        repository: FakeAdminStaffRepository(
          accounts: <StaffAccount>[accounts.last],
        ),
      );

      await tapVisible(tester, find.text('Penjaga').first);

      expect(find.text('Belum ada akun penjaga'), findsOneWidget);
    });

    testWidgets('tidak meluap di layar 320 px', (tester) async {
      await open(
        tester,
        location: staffRoute,
        size: const Size(320, 640),
        repository: FakeAdminStaffRepository(
          accounts: <StaffAccount>[
            staffAccount(
              name: 'Kusumawardhani Anindya Prameswari Putri',
              email: 'kusumawardhani.anindya.prameswari@contoh-panjang.com',
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('tambah akun staf', () {
    testWidgets('isian kosong menampilkan galat per kolom', (tester) async {
      final FakeAdminStaffRepository repository = await open(
        tester,
        location: createRoute,
      );

      await tapVisible(tester, find.text('Buat akun'));

      expect(find.text('Nama lengkap wajib diisi.'), findsOneWidget);
      expect(find.text('Alamat email wajib diisi.'), findsOneWidget);
      expect(find.text('Kata sandi minimal 8 karakter.'), findsOneWidget);
      expect(repository.created, isEmpty);
    });

    testWidgets('membuat admin lalu kembali ke daftar', (tester) async {
      final FakeAdminStaffRepository repository = await open(
        tester,
        location: staffRoute,
      );
      await tapVisible(tester, find.text('Tambah akun staf'));
      await tester.pumpAndSettle();

      await enterInField(tester, 0, 'Sarah Oktavia');
      await enterInField(tester, 1, 'sarah@contoh.com');
      await enterInField(tester, 2, 'rahasia123');
      await tapVisible(tester, find.byType(RoleOptionCard).last);
      await tapVisible(tester, find.text('Buat akun'));
      await tester.pumpAndSettle();

      expect(repository.created.single.role, UserRole.admin);
      expect(find.text('Akun Sarah Oktavia dibuat sebagai admin.'), findsOne);
      expect(find.text('Sarah Oktavia'), findsOneWidget);
    });

    testWidgets('email yang sudah dipakai tampil sebagai galat', (
      tester,
    ) async {
      await open(
        tester,
        location: createRoute,
        repository: FakeAdminStaffRepository(
          createError: const ConflictException(
            'Email ini sudah dipakai akun lain.',
          ),
        ),
      );

      await enterInField(tester, 0, 'Sarah Oktavia');
      await enterInField(tester, 1, 'sarah@contoh.com');
      await enterInField(tester, 2, 'rahasia123');
      await tapVisible(tester, find.text('Buat akun'));

      expect(find.text('Email ini sudah dipakai akun lain.'), findsOneWidget);
    });
  });
}
