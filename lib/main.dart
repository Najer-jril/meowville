import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/routes/app_router.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/clock.dart';
import 'features/admin_bookings/data/datasources/admin_booking_remote_datasource.dart';
import 'features/admin_bookings/data/repositories/admin_booking_repository_impl.dart';
import 'features/admin_bookings/domain/repositories/admin_booking_repository.dart';
import 'features/admin_manage/data/datasources/admin_staff_remote_datasource.dart';
import 'features/admin_manage/data/repositories/admin_staff_repository_impl.dart';
import 'features/admin_manage/domain/repositories/admin_staff_repository.dart';
import 'features/admin_pawrents/data/datasources/admin_pawrent_remote_datasource.dart';
import 'features/admin_pawrents/data/repositories/admin_pawrent_repository_impl.dart';
import 'features/admin_pawrents/domain/repositories/admin_pawrent_repository.dart';
import 'features/admin_rooms/data/datasources/admin_room_remote_datasource.dart';
import 'features/admin_rooms/data/repositories/admin_room_repository_impl.dart';
import 'features/admin_rooms/domain/repositories/admin_room_repository.dart';
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
import 'features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'features/dashboard/domain/repositories/dashboard_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MeowvilleApp());
}

class MeowvilleApp extends StatefulWidget {
  const MeowvilleApp({super.key});

  @override
  State<MeowvilleApp> createState() => _MeowvilleAppState();
}

class _MeowvilleAppState extends State<MeowvilleApp> {
  late final AuthRepository _authRepository = AuthRepositoryImpl(
    AuthRemoteDataSource(supabase),
  );
  late final DashboardRepository _dashboardRepository = DashboardRepositoryImpl(
    SupabaseDashboardRemoteDataSource(supabase),
    (String bucket, String path) =>
        supabase.storage.from(bucket).getPublicUrl(path),
  );
  late final AdminBookingRepository _adminBookingRepository =
      AdminBookingRepositoryImpl(
        SupabaseAdminBookingRemoteDataSource(supabase),
      );
  late final AdminPawrentRepository _adminPawrentRepository =
      AdminPawrentRepositoryImpl(
        SupabaseAdminPawrentRemoteDataSource(supabase),
      );
  late final AdminRoomRepository _adminRoomRepository = AdminRoomRepositoryImpl(
    SupabaseAdminRoomRemoteDataSource(supabase),
  );
  late final AdminStaffRepository _adminStaffRepository =
      AdminStaffRepositoryImpl(SupabaseAdminStaffRemoteDataSource(supabase));
  late final AuthNotifier _authNotifier = AuthNotifier(
    _authRepository,
    SignOutUseCase(_authRepository),
  );
  late final AppRouter _appRouter = AppRouter(_authNotifier);

  @override
  void dispose() {
    _authNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        Provider<AuthRepository>.value(value: _authRepository),
        Provider<DashboardRepository>.value(value: _dashboardRepository),
        Provider<AdminBookingRepository>.value(value: _adminBookingRepository),
        Provider<AdminPawrentRepository>.value(value: _adminPawrentRepository),
        Provider<AdminRoomRepository>.value(value: _adminRoomRepository),
        Provider<AdminStaffRepository>.value(value: _adminStaffRepository),
        Provider<Clock>.value(value: DateTime.now),
        ChangeNotifierProvider<AuthNotifier>.value(value: _authNotifier),
        ChangeNotifierProvider<LoginController>(
          create: (_) => LoginController(SignInUseCase(_authRepository)),
        ),
        ChangeNotifierProvider<RegisterOwnerController>(
          create: (_) =>
              RegisterOwnerController(RegisterOwnerUseCase(_authRepository)),
        ),
        ChangeNotifierProvider<RegisterSitterController>(
          create: (_) =>
              RegisterSitterController(RegisterSitterUseCase(_authRepository)),
        ),
      ],
      child: MaterialApp.router(
        title: 'Meowville',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _appRouter.router,
      ),
    );
  }
}
