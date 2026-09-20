import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/routes/app_router.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/register_account_usecase.dart';
import 'features/auth/domain/usecases/sign_in_usecase.dart';
import 'features/auth/domain/usecases/sign_out_usecase.dart';
import 'features/auth/presentation/providers/auth_notifier.dart';
import 'features/auth/presentation/providers/login_controller.dart';
import 'features/auth/presentation/providers/register_owner_controller.dart';
import 'features/auth/presentation/providers/register_sitter_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MeowvilleApp());
}

class MeowvilleApp extends StatelessWidget {
  const MeowvilleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthRepository authRepository = AuthRepositoryImpl(
      AuthRemoteDataSource(supabase),
    );

    return MultiProvider(
      providers: <SingleChildWidget>[
        Provider<AuthRepository>.value(value: authRepository),
        ChangeNotifierProvider<AuthNotifier>(
          create: (_) =>
              AuthNotifier(authRepository, SignOutUseCase(authRepository)),
        ),
        ChangeNotifierProvider<LoginController>(
          create: (_) => LoginController(SignInUseCase(authRepository)),
        ),
        ChangeNotifierProvider<RegisterOwnerController>(
          create: (_) =>
              RegisterOwnerController(RegisterOwnerUseCase(authRepository)),
        ),
        ChangeNotifierProvider<RegisterSitterController>(
          create: (_) =>
              RegisterSitterController(RegisterSitterUseCase(authRepository)),
        ),
      ],
      child: Builder(
        builder: (BuildContext context) {
          final AuthNotifier authNotifier = context.watch<AuthNotifier>();
          final AppRouter appRouter = AppRouter(authNotifier);

          return MaterialApp.router(
            title: 'Meowville',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: appRouter.router,
          );
        },
      ),
    );
  }
}
