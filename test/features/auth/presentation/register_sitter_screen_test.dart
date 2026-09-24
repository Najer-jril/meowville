import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meowville/core/theme/app_theme.dart';
import 'package:meowville/features/auth/domain/entities/user_role.dart';
import 'package:meowville/features/auth/domain/usecases/register_account_usecase.dart';
import 'package:meowville/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:meowville/features/auth/presentation/providers/auth_notifier.dart';
import 'package:meowville/features/auth/presentation/providers/register_sitter_controller.dart';
import 'package:meowville/features/auth/presentation/screens/register_sitter_screen.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'fake_auth_repository.dart';

void main() {
  Future<RegisterSitterController> pumpSitterScreen(
    WidgetTester tester,
    FakeAuthRepository repository, {
    Size viewport = const Size(393, 852),
  }) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final RegisterSitterController controller = RegisterSitterController(
      RegisterSitterUseCase(repository),
    );

    final GoRouter router = GoRouter(
      initialLocation: '/register-penjaga',
      routes: <RouteBase>[
        GoRoute(
          path: '/register-penjaga',
          builder: (BuildContext context, GoRouterState state) =>
              const RegisterSitterScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (BuildContext context, GoRouterState state) =>
              const Scaffold(body: Text('layar daftar pemilik')),
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
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<RegisterSitterController>.value(
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

  testWidgets('pendaftaran penjaga mengirim peran pet_sitter', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    final RegisterSitterController controller = await pumpSitterScreen(
      tester,
      repository,
    );
    controller.nameController.text = 'Bagas Nugroho';
    controller.emailController.text = 'bagas@contoh.com';
    controller.whatsappController.text = '081234567890';
    controller.passwordController.text = 'rahasia123';
    controller.confirmPasswordController.text = 'rahasia123';
    controller.setTermsAccepted(true);
    await tester.pumpAndSettle();

    final Finder submit = find.text('Buat Akun Penjaga');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(repository.registerCalls, hasLength(1));
    expect(repository.registerCalls.single.role, UserRole.petSitter);
  });

  testWidgets('tautan daftar pemilik menuju layar pemilik', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await pumpSitterScreen(tester, repository);

    final Finder link = find.text('Daftar akun pemilik');
    await tester.ensureVisible(link);
    await tester.pumpAndSettle();
    await tester.tap(link);
    await tester.pumpAndSettle();

    expect(find.text('layar daftar pemilik'), findsOneWidget);
  });

  testWidgets('tidak ada luapan mendatar pada lebar telepon sempit', (
    WidgetTester tester,
  ) async {
    final FakeAuthRepository repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await pumpSitterScreen(tester, repository, viewport: const Size(320, 640));

    expect(tester.takeException(), isNull);
  });
}
