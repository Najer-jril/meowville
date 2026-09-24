import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meowville/features/auth/domain/entities/user_role.dart';
import 'package:meowville/features/auth/presentation/screens/login_screen.dart';
import 'package:meowville/features/dashboard/presentation/screens/sitter_dashboard_screen.dart';
import 'package:meowville/features/shell/presentation/nav_destination.dart';
import 'package:meowville/features/shell/presentation/role_bottom_nav.dart';

import '../../support/app_harness.dart';
import '../auth/presentation/fake_auth_repository.dart';

void main() {
  Finder navLabel(String label) => find.descendant(
    of: find.byType(RoleBottomNav),
    matching: find.text(label),
  );

  Future<FakeAuthRepository> open(
    WidgetTester tester,
    UserRole role, {
    Size size = const Size(393, 852),
    String? location,
  }) async {
    final FakeAuthRepository repository = FakeAuthRepository(
      initialUser: userWithRole(role),
    );
    addTearDown(repository.dispose);
    await pumpApp(tester, repository, size: size, location: location);
    await tester.pumpAndSettle();
    return repository;
  }

  group('bar navigasi per peran', () {
    for (final (UserRole role, List<String> labels)
        in <(UserRole, List<String>)>[
          (
            UserRole.petOwner,
            <String>['Beranda', 'Kamar', 'Reservasi', 'Laporan', 'Kucingku'],
          ),
          (
            UserRole.petSitter,
            <String>['Tugas', 'Tamu', 'Catat', 'Riwayat', 'Profil'],
          ),
          (
            UserRole.admin,
            <String>['Dashboard', 'Reservasi', 'Kamar', 'Pawrent', 'Kelola'],
          ),
        ]) {
      testWidgets('${role.wireValue} melihat lima tabnya', (tester) async {
        await open(tester, role);

        for (final String label in labels) {
          expect(navLabel(label), findsOneWidget, reason: label);
        }
      });
    }

    test('setiap tab punya rute unik berawalan peran', () {
      for (final (UserRole role, String prefix) in <(UserRole, String)>[
        (UserRole.petOwner, '/pemilik'),
        (UserRole.petSitter, '/penjaga'),
        (UserRole.admin, '/admin'),
      ]) {
        final List<String> routes = RoleNavigation.forRole(role)
            .map((NavDestination d) => d.route)
            .toList();
        expect(routes.toSet(), hasLength(5));
        expect(routes.every((String r) => r.startsWith(prefix)), isTrue);
      }
    });

    test('sub-rute menyalakan tab induknya', () {
      expect(RoleNavigation.indexFor(RoleNavigation.owner, '/pemilik'), 0);
      expect(
        RoleNavigation.indexFor(RoleNavigation.owner, '/pemilik/kamar'),
        1,
      );
      expect(
        RoleNavigation.indexFor(RoleNavigation.owner, '/pemilik/kamar/2'),
        1,
      );
      expect(
        RoleNavigation.indexFor(RoleNavigation.admin, '/admin/laporan'),
        0,
      );
      expect(RoleNavigation.indexFor(RoleNavigation.admin, '/login'), -1);
    });
  });

  group('pindah tab', () {
    testWidgets('setiap tab pemilik membuka layar sungguhan berlabel', (
      tester,
    ) async {
      await open(tester, UserRole.petOwner);

      for (final NavDestination destination in RoleNavigation.owner.skip(1)) {
        await tester.tap(navLabel(destination.label));
        await tester.pumpAndSettle();

        expect(find.text('Belum dibangun'), findsOneWidget);
        expect(find.text(destination.placeholderSummary), findsOneWidget);
        expect(navLabel('Beranda'), findsOneWidget);
      }
    });

    testWidgets('tombol Catat penjaga menuju layar Catat', (tester) async {
      await open(tester, UserRole.petSitter);

      await tester.tap(navLabel('Catat'));
      await tester.pumpAndSettle();

      expect(find.byType(SitterDashboardScreen), findsNothing);
      expect(
        find.text('Tulis laporan harian untuk kucing yang menginap.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'rute di luar bar (admin laporan) terbuka di bawah tab Dashboard',
      (tester) async {
        await open(tester, UserRole.admin, location: '/admin/laporan');

        expect(find.text('Belum dibangun'), findsOneWidget);
        expect(navLabel('Dashboard'), findsOneWidget);
      },
    );

    testWidgets('kembali ke tab dashboard menampilkan dashboard lagi', (
      tester,
    ) async {
      await open(tester, UserRole.petSitter);
      await tester.tap(navLabel('Tamu'));
      await tester.pumpAndSettle();
      await tester.tap(navLabel('Tugas'));
      await tester.pumpAndSettle();

      expect(find.byType(SitterDashboardScreen), findsOneWidget);
    });
  });

  testWidgets('tombol keluar akun mengembalikan pengguna ke layar masuk', (
    tester,
  ) async {
    await open(tester, UserRole.petOwner);

    await tester.tap(find.byTooltip('Keluar akun'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  group('tanpa luapan pada 320 px', () {
    for (final UserRole role in UserRole.values) {
      testWidgets('${role.wireValue}, teks normal', (tester) async {
        await open(tester, role, size: const Size(320, 640));
        expect(tester.takeException(), isNull);
      });

      testWidgets('${role.wireValue}, teks diperbesar 1,5x', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await open(tester, role, size: const Size(320, 640));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
