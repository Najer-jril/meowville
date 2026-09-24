import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meowville/core/errors/app_exception.dart';
import 'package:meowville/core/theme/app_theme.dart';
import 'package:meowville/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:meowville/features/auth/presentation/providers/login_controller.dart';
import 'package:meowville/features/auth/presentation/screens/login_screen.dart';
import 'package:provider/provider.dart';

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

  Future<LoginController> pumpLoginScreen(
    WidgetTester tester,
    FakeAuthRepository repository, {
    Size viewport = const Size(393, 852),
  }) async {
    useDesignViewport(tester, size: viewport);
    final LoginController controller = LoginController(
      SignInUseCase(repository),
    );

    final GoRouter router = GoRouter(
      initialLocation: '/login',
      routes: <RouteBase>[
        GoRoute(
          path: '/login',
          builder: (BuildContext context, GoRouterState state) =>
              const LoginScreen(),
        ),
        GoRoute(
          path: '/lupa-sandi',
          builder: (BuildContext context, GoRouterState state) =>
              const Scaffold(body: Text('layar lupa kata sandi')),
        ),
        GoRoute(
          path: '/register',
          builder: (BuildContext context, GoRouterState state) =>
              const Scaffold(body: Text('layar daftar')),
        ),
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const Scaffold(body: Text('beranda')),
        ),
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<LoginController>.value(
        value: controller,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('tombol tampilkan kata sandi mengubah status tersembunyi', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    final LoginController controller = await pumpLoginScreen(
      tester,
      repository,
    );
    expect(controller.obscurePassword, isTrue);

    await tapVisible(
      tester,
      find.bySemanticsLabel('Tampilkan kata sandi').first,
    );

    expect(controller.obscurePassword, isFalse);
  });

  testWidgets('kotak Ingat Saya berpindah status saat ditekan', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    final LoginController controller = await pumpLoginScreen(
      tester,
      repository,
    );
    expect(controller.rememberMe, isFalse);

    await tapVisible(tester, find.bySemanticsLabel('Ingat Saya').first);

    expect(controller.rememberMe, isTrue);
  });

  testWidgets(
    'mengirim form kosong memunculkan galat, bukan permintaan masuk',
    (WidgetTester tester) async {
      final FakeAuthRepository repository = FakeAuthRepository();
      addTearDown(repository.dispose);

      await pumpLoginScreen(tester, repository);

      await tapVisible(tester, find.text('Masuk ke Akun'));

      expect(repository.signInCalls, isEmpty);
      expect(
        find.text('Email atau nomor WhatsApp wajib diisi.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('kredensial ditolak menampilkan spanduk galat', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository repository = FakeAuthRepository(
      signInError: const UnauthorizedException(
        'Email atau kata sandi tidak cocok.',
      ),
    );
    addTearDown(repository.dispose);

    final LoginController controller = await pumpLoginScreen(
      tester,
      repository,
    );
    controller.identifierController.text = 'rani@contoh.com';
    controller.passwordController.text = 'rahasia123';

    await tapVisible(tester, find.text('Masuk ke Akun'));

    expect(repository.signInCalls, hasLength(1));
    expect(find.text('Email atau kata sandi tidak cocok.'), findsOneWidget);
  });

  testWidgets('tautan Lupa Kata Sandi membuka layar pemulihan', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await pumpLoginScreen(tester, repository);

    await tapVisible(tester, find.text('Lupa Kata Sandi?'));

    expect(find.text('layar lupa kata sandi'), findsOneWidget);
  });

  testWidgets('tautan Daftar Sekarang berpindah ke layar daftar', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await pumpLoginScreen(tester, repository);

    await tapVisible(tester, find.text('Daftar Sekarang'));

    expect(find.text('layar daftar'), findsOneWidget);
  });

  testWidgets('tidak ada luapan mendatar pada lebar telepon sempit', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await pumpLoginScreen(tester, repository, viewport: const Size(320, 640));

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'baris Ingat Saya dan Lupa Kata Sandi muat saat teks diperbesar',
    (WidgetTester tester) async {
      final FakeAuthRepository repository = FakeAuthRepository();
      addTearDown(repository.dispose);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpLoginScreen(tester, repository, viewport: const Size(320, 640));

      expect(find.text('Ingat Saya'), findsOneWidget);
      expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
