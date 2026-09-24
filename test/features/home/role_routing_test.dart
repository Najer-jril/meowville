import 'package:flutter_test/flutter_test.dart';
import 'package:meowville/app/routes/app_router.dart';
import 'package:meowville/features/auth/domain/entities/user_role.dart';
import 'package:meowville/features/auth/presentation/screens/login_screen.dart';
import 'package:meowville/features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import 'package:meowville/features/dashboard/presentation/screens/owner_dashboard_screen.dart';
import 'package:meowville/features/dashboard/presentation/screens/sitter_dashboard_screen.dart';
import 'package:meowville/features/home/presentation/role_home_config.dart';

import '../../support/app_harness.dart';
import '../auth/presentation/fake_auth_repository.dart';

void main() {
  FakeAuthRepository repositoryFor(UserRole? role) =>
      FakeAuthRepository(initialUser: role == null ? null : userWithRole(role));

  group('pendaratan awal', () {
    testWidgets('pemilik mendarat di dashboard pemilik', (tester) async {
      final FakeAuthRepository repository = repositoryFor(UserRole.petOwner);
      addTearDown(repository.dispose);
      await pumpApp(tester, repository);
      expect(find.byType(OwnerDashboardScreen), findsOneWidget);
    });

    testWidgets('penjaga mendarat di dashboard penjaga', (tester) async {
      final FakeAuthRepository repository = repositoryFor(UserRole.petSitter);
      addTearDown(repository.dispose);
      await pumpApp(tester, repository);
      expect(find.byType(SitterDashboardScreen), findsOneWidget);
    });

    testWidgets('admin mendarat di dashboard admin', (tester) async {
      final FakeAuthRepository repository = repositoryFor(UserRole.admin);
      addTearDown(repository.dispose);
      await pumpApp(tester, repository);
      expect(find.byType(AdminDashboardScreen), findsOneWidget);
    });
  });

  group('penjagaan lintas peran', () {
    testWidgets('penjaga yang menebak /admin dikembalikan ke berandanya', (
      tester,
    ) async {
      final FakeAuthRepository repository = repositoryFor(UserRole.petSitter);
      addTearDown(repository.dispose);
      await pumpApp(tester, repository, location: '/admin');

      expect(find.byType(AdminDashboardScreen), findsNothing);
      expect(find.byType(SitterDashboardScreen), findsOneWidget);
    });

    testWidgets('sub-rute peran lain tertutup: /admin/kamar bagi penjaga', (
      tester,
    ) async {
      final FakeAuthRepository repository = repositoryFor(UserRole.petSitter);
      addTearDown(repository.dispose);
      await pumpApp(tester, repository, location: '/admin/kamar');

      expect(find.byType(SitterDashboardScreen), findsOneWidget);
      expect(find.text('Belum dibangun'), findsNothing);
    });

    testWidgets('sub-rute pemilik tertutup bagi admin', (tester) async {
      final FakeAuthRepository repository = repositoryFor(UserRole.admin);
      addTearDown(repository.dispose);
      await pumpApp(tester, repository, location: '/pemilik/kucing');

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
    });

    testWidgets('sub-rute milik sendiri tetap terbuka', (tester) async {
      final FakeAuthRepository repository = repositoryFor(UserRole.admin);
      addTearDown(repository.dispose);
      // Sub-rute Kelola yang layarnya belum dibangun tetap milik admin.
      await pumpApp(tester, repository, location: '/admin/kelola/laporan');

      expect(find.byType(AdminDashboardScreen), findsNothing);
      expect(find.text('Belum dibangun'), findsOneWidget);
    });

    testWidgets('tanpa sesi, area peran dialihkan ke layar masuk', (
      tester,
    ) async {
      final FakeAuthRepository repository = repositoryFor(null);
      addTearDown(repository.dispose);
      await pumpApp(tester, repository, location: '/pemilik/reservasi');

      expect(find.byType(OwnerDashboardScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('RoleHomeConfig.roleForLocation', () {
    test('mencocokkan per awalan segmen, bukan per awalan huruf', () {
      expect(RoleHomeConfig.roleForLocation('/admin'), UserRole.admin);
      expect(RoleHomeConfig.roleForLocation('/admin/kamar'), UserRole.admin);
      expect(RoleHomeConfig.roleForLocation('/adminx'), isNull);
      expect(
        RoleHomeConfig.roleForLocation('/penjaga/tamu'),
        UserRole.petSitter,
      );
      expect(RoleHomeConfig.roleForLocation('/login'), isNull);
    });
  });

  test('AppRouter mengekspos rute pemulihan', () {
    expect(AppRouter.forgotPassword, '/lupa-sandi');
    expect(AppRouter.resetPassword, '/atur-ulang-sandi');
  });
}
