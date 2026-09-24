import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meowville/app/routes/app_router.dart';
import 'package:meowville/core/theme/app_theme.dart';
import 'package:meowville/core/utils/clock.dart';
import 'package:meowville/features/admin_bookings/domain/repositories/admin_booking_repository.dart';
import 'package:meowville/features/admin_manage/domain/repositories/admin_staff_repository.dart';
import 'package:meowville/features/admin_pawrents/domain/repositories/admin_pawrent_repository.dart';
import 'package:meowville/features/admin_rooms/domain/repositories/admin_room_repository.dart';
import 'package:meowville/features/auth/domain/entities/auth_user.dart';
import 'package:meowville/features/auth/domain/entities/user_role.dart';
import 'package:meowville/features/auth/domain/repositories/auth_repository.dart';
import 'package:meowville/features/auth/domain/usecases/register_account_usecase.dart';
import 'package:meowville/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:meowville/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:meowville/features/auth/presentation/providers/auth_notifier.dart';
import 'package:meowville/features/auth/presentation/providers/login_controller.dart';
import 'package:meowville/features/auth/presentation/providers/register_owner_controller.dart';
import 'package:meowville/features/auth/presentation/providers/register_sitter_controller.dart';
import 'package:meowville/features/dashboard/domain/entities/admin_dashboard.dart';
import 'package:meowville/features/dashboard/domain/entities/owner_dashboard.dart';
import 'package:meowville/features/dashboard/domain/entities/sitter_dashboard.dart';
import 'package:meowville/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/admin_bookings/fake_admin_booking_repository.dart';
import '../features/admin_manage/fake_admin_staff_repository.dart';
import '../features/admin_pawrents/fake_admin_pawrent_repository.dart';
import '../features/admin_rooms/fake_admin_room_repository.dart';
import '../features/auth/presentation/fake_auth_repository.dart';
import '../features/dashboard/dashboard_fixtures.dart';

AuthUser userWithRole(UserRole role, {String name = 'Rani Pratama'}) {
  return AuthUser(
    id: '00000000-0000-4000-8000-000000000001',
    name: name,
    email: 'rani@contoh.com',
    whatsappNumber: '081234567890',
    role: role,
    createdAt: DateTime.utc(2026, 9, 9),
  );
}

OwnerDashboard emptyOwnerDashboard() => OwnerDashboard.compose(
  bookings: const [],
  pets: const [],
  rooms: const [],
  todayLogs: const [],
  today: today,
);

SitterDashboard emptySitterDashboard() => SitterDashboard.compose(
  guests: const [],
  todayLogs: const [],
  today: today,
);

AdminDashboard emptyAdminDashboard() => AdminDashboard.compose(
  liveBookings: const [],
  recent: const [],
  rooms: const [],
  units: const [],
  blocks: const [],
  todayLogs: const [],
  servicesByBooking: const {},
  today: today,
);

FakeDashboardRepository emptyDashboardRepository() => FakeDashboardRepository(
  owner: emptyOwnerDashboard(),
  sitter: emptySitterDashboard(),
  admin: emptyAdminDashboard(),
);

DateTime fixedNow() => DateTime(2026, 10, 12, 14);

Future<AppRouter> pumpApp(
  WidgetTester tester,
  FakeAuthRepository repository, {
  DashboardRepository? dashboardRepository,
  AdminBookingRepository? adminBookingRepository,
  AdminRoomRepository? adminRoomRepository,
  AdminPawrentRepository? adminPawrentRepository,
  AdminStaffRepository? adminStaffRepository,
  Size size = const Size(393, 852),
  String? location,
  Object? extra,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final AuthNotifier authNotifier = AuthNotifier(
    repository,
    SignOutUseCase(repository),
  );
  addTearDown(authNotifier.dispose);
  final AppRouter appRouter = AppRouter(authNotifier);

  await tester.pumpWidget(
    MultiProvider(
      providers: <SingleChildWidget>[
        Provider<AuthRepository>.value(value: repository),
        Provider<DashboardRepository>.value(
          value: dashboardRepository ?? emptyDashboardRepository(),
        ),
        Provider<AdminBookingRepository>.value(
          value: adminBookingRepository ?? FakeAdminBookingRepository(),
        ),
        Provider<AdminRoomRepository>.value(
          value: adminRoomRepository ?? FakeAdminRoomRepository(),
        ),
        Provider<AdminPawrentRepository>.value(
          value: adminPawrentRepository ?? FakeAdminPawrentRepository(),
        ),
        Provider<AdminStaffRepository>.value(
          value: adminStaffRepository ?? FakeAdminStaffRepository(),
        ),
        Provider<Clock>.value(value: fixedNow),
        ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),
        ChangeNotifierProvider<LoginController>(
          create: (_) => LoginController(SignInUseCase(repository)),
        ),
        ChangeNotifierProvider<RegisterOwnerController>(
          create: (_) =>
              RegisterOwnerController(RegisterOwnerUseCase(repository)),
        ),
        ChangeNotifierProvider<RegisterSitterController>(
          create: (_) =>
              RegisterSitterController(RegisterSitterUseCase(repository)),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: appRouter.router,
      ),
    ),
  );
  await settleBriefly(tester);

  if (location != null) {
    appRouter.router.go(location, extra: extra);
    await settleBriefly(tester);
  }
  return appRouter;
}

Future<void> settleBriefly(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await settleBriefly(tester);
  await tester.tap(finder);
  await settleBriefly(tester);
}

Future<void> enterInField(WidgetTester tester, int index, String text) async {
  final Finder field = find.byType(TextField).at(index);
  await tester.ensureVisible(field);
  await settleBriefly(tester);
  await tester.enterText(field, text);
  await settleBriefly(tester);
}
