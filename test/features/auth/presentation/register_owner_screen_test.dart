import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meowville/core/errors/app_exception.dart';
import 'package:meowville/core/theme/app_theme.dart';
import 'package:meowville/features/auth/domain/usecases/register_account_usecase.dart';
import 'package:meowville/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:meowville/features/auth/presentation/providers/auth_notifier.dart';
import 'package:meowville/features/auth/presentation/providers/register_owner_controller.dart';
import 'package:meowville/features/auth/presentation/screens/register_owner_screen.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'fake_auth_repository.dart';

void main() {
  void useDesignViewport(
    WidgetTester tester, {
    Size size = const Size(393, 852),
  }) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<RegisterOwnerController> pumpRegisterScreen(
    WidgetTester tester,
    FakeAuthRepository repository, {
    Size viewport = const Size(393, 852),
  }) async {
    useDesignViewport(tester, size: viewport);
    final RegisterOwnerController controller = RegisterOwnerController(
      RegisterOwnerUseCase(repository),
    );

    final GoRouter router = GoRouter(
      initialLocation: '/register',
      routes: <RouteBase>[
        GoRoute(
          path: '/register',
          builder: (BuildContext context, GoRouterState state) =>
              const RegisterOwnerScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (BuildContext context, GoRouterState state) =>
              const Scaffold(body: Text('layar masuk')),
        ),
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const Scaffold(body: Text('beranda')),
        ),
        GoRoute(
          path: '/legal/ketentuan-layanan',
          builder: (BuildContext context, GoRouterState state) =>
              const Scaffold(body: Text('layar ketentuan layanan')),
        ),
        GoRoute(
          path: '/legal/kebijakan-privasi',
          builder: (BuildContext context, GoRouterState state) =>
              const Scaffold(body: Text('layar kebijakan privasi')),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<RegisterOwnerController>.value(
            value: controller,
          ),
          ChangeNotifierProvider<AuthNotifier>(
            create: (_) => AuthNotifier(repository, SignOutUseCase(repository)),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets(
    'kolom Nomor WhatsApp dan konfirmasi sandi tersedia di layar daftar',
    (WidgetTester tester) async {
      final FakeAuthRepository repository = FakeAuthRepository();
      addTearDown(repository.dispose);

      await pumpRegisterScreen(tester, repository);

      expect(find.text('Nomor WhatsApp'), findsOneWidget);
      expect(find.text('Konfirmasi Kata Sandi'), findsOneWidget);
    },
  );

  testWidgets('mengirim tanpa persetujuan menahan permintaan daftar', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    final RegisterOwnerController controller = await pumpRegisterScreen(
      tester,
      repository,
    );
    controller.nameController.text = 'Rani Pratama';
    controller.emailController.text = 'rani@contoh.com';
    controller.whatsappController.text = '081234567890';
    controller.passwordController.text = 'rahasia123';
    controller.confirmPasswordController.text = 'rahasia123';

    await tapVisible(tester, find.text('Buat Akun Meowville'));

    expect(repository.registerCalls, isEmpty);
    expect(
      find.text('Centang persetujuan ketentuan layanan untuk melanjutkan.'),
      findsOneWidget,
    );
  });

  testWidgets('pendaftaran lengkap membakukan nomor sebelum dikirim', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    final RegisterOwnerController controller = await pumpRegisterScreen(
      tester,
      repository,
    );
    controller.nameController.text = 'Rani Pratama';
    controller.emailController.text = 'Rani@Contoh.com';
    controller.whatsappController.text = '+62 812-3456-7890';
    controller.passwordController.text = 'rahasia123';
    controller.confirmPasswordController.text = 'rahasia123';
    controller.setTermsAccepted(true);
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Buat Akun Meowville'));

    expect(repository.registerCalls, hasLength(1));
    expect(repository.registerCalls.single.whatsappNumber, '081234567890');
    expect(repository.registerCalls.single.email, 'rani@contoh.com');
  });

  testWidgets('email ganda menampilkan spanduk galat', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository repository = FakeAuthRepository(
      registerError: const ConflictException(
        'Email itu sudah dipakai akun lain.',
      ),
    );
    addTearDown(repository.dispose);

    final RegisterOwnerController controller = await pumpRegisterScreen(
      tester,
      repository,
    );
    controller.nameController.text = 'Rani Pratama';
    controller.emailController.text = 'rani@contoh.com';
    controller.whatsappController.text = '081234567890';
    controller.passwordController.text = 'rahasia123';
    controller.confirmPasswordController.text = 'rahasia123';
    controller.setTermsAccepted(true);
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Buat Akun Meowville'));

    expect(find.text('Email itu sudah dipakai akun lain.'), findsOneWidget);
  });

  testWidgets('tautan Ketentuan Layanan membuka dokumen ketentuan', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await pumpRegisterScreen(tester, repository);

    await tester.ensureVisible(find.textContaining('Saya menyetujui'));
    await tester.pumpAndSettle();
    await tester.tapOnText(
      find.textRange.ofSubstring('Ketentuan Layanan Penitipan'),
    );
    await tester.pumpAndSettle();

    expect(find.text('layar ketentuan layanan'), findsOneWidget);
  });

  testWidgets('tautan Masuk di sini menuju layar masuk', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await pumpRegisterScreen(tester, repository);

    await tapVisible(tester, find.text('Masuk di sini'));

    expect(find.text('layar masuk'), findsOneWidget);
  });

  testWidgets('konfirmasi kata sandi berbeda menahan permintaan daftar', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    final RegisterOwnerController controller = await pumpRegisterScreen(
      tester,
      repository,
    );
    controller.nameController.text = 'Rani Pratama';
    controller.emailController.text = 'rani@contoh.com';
    controller.whatsappController.text = '081234567890';
    controller.passwordController.text = 'rahasia123';
    controller.confirmPasswordController.text = 'rahasia124';
    controller.setTermsAccepted(true);
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Buat Akun Meowville'));

    expect(repository.registerCalls, isEmpty);
    expect(
      find.text('Konfirmasi kata sandi belum sama dengan kata sandi.'),
      findsOneWidget,
    );
  });

  testWidgets('tidak ada luapan pada lebar telepon sempit', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await pumpRegisterScreen(
      tester,
      repository,
      viewport: const Size(320, 640),
    );

    expect(tester.takeException(), isNull);
  });
}
