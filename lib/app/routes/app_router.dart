import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/auth_routes.dart';
import '../../core/navigation/legal_routes.dart';
import '../../features/admin_bookings/presentation/admin_booking_routes.dart';
import '../../features/admin_bookings/presentation/screens/admin_booking_detail_screen.dart';
import '../../features/admin_bookings/presentation/screens/admin_booking_list_screen.dart';
import '../../features/admin_manage/presentation/admin_manage_routes.dart';
import '../../features/admin_manage/presentation/screens/admin_manage_pending_screen.dart';
import '../../features/admin_manage/presentation/screens/admin_manage_screen.dart';
import '../../features/admin_manage/presentation/screens/admin_staff_form_screen.dart';
import '../../features/admin_manage/presentation/screens/admin_staff_list_screen.dart';
import '../../features/admin_pawrents/presentation/admin_pawrent_routes.dart';
import '../../features/admin_pawrents/presentation/screens/admin_pawrent_detail_screen.dart';
import '../../features/admin_pawrents/presentation/screens/admin_pawrent_list_screen.dart';
import '../../features/admin_rooms/presentation/admin_room_routes.dart';
import '../../features/admin_rooms/presentation/screens/admin_room_form_screen.dart';
import '../../features/admin_rooms/presentation/screens/admin_rooms_screen.dart';
import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/auth/domain/entities/user_role.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_owner_screen.dart';
import '../../features/auth/presentation/screens/register_sitter_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/owner_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/sitter_dashboard_screen.dart';
import '../../features/home/presentation/role_home_config.dart';
import '../../features/shell/presentation/nav_destination.dart';
import '../../features/shell/presentation/role_shell.dart';
import '../../features/shell/presentation/screens/placeholder_screen.dart';
import '../../features/legal/data/legal_documents.dart';
import '../../features/legal/presentation/screens/legal_document_screen.dart';
import '../../features/splash/presentation/screens/session_check_screen.dart';

class AppRouter {
  AppRouter(this.authNotifier);

  final AuthNotifier authNotifier;

  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String registerSitter = '/register-penjaga';
  static const String forgotPassword = AuthRoutes.forgotPassword;
  static const String resetPassword = AuthRoutes.resetPassword;
  static const String sessionCheck = '/memeriksa-sesi';

  late final GoRouter router = GoRouter(
    refreshListenable: authNotifier,
    initialLocation: sessionCheck,
    redirect: (BuildContext context, GoRouterState state) {
      final String location = state.matchedLocation;

      if (authNotifier.isChecking) {
        return location == sessionCheck ? null : sessionCheck;
      }

      final bool onAuthScreen =
          location == login ||
          location == register ||
          location == registerSitter ||
          location == forgotPassword;
      final bool onPublicScreen =
          onAuthScreen || LegalRoutes.coversLocation(location);

      if (location == resetPassword) {
        return null;
      }

      final AuthUser? user = authNotifier.user;
      if (user == null) {
        return onPublicScreen ? null : login;
      }

      final String roleHome = RoleHomeConfig.forRole(user.role).route;

      if (onAuthScreen || location == sessionCheck || location == home) {
        return roleHome;
      }
      final UserRole? routeOwner = RoleHomeConfig.roleForLocation(location);
      if (routeOwner != null && routeOwner != user.role) {
        return roleHome;
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: sessionCheck,
        builder: (BuildContext context, GoRouterState state) =>
            const SessionCheckScreen(),
      ),
      GoRoute(
        path: home,
        builder: (BuildContext context, GoRouterState state) =>
            const SessionCheckScreen(),
      ),
      _roleShell(
        role: UserRole.petOwner,
        destinations: RoleNavigation.owner,
        dashboard: const OwnerDashboardScreen(),
      ),
      _roleShell(
        role: UserRole.petSitter,
        destinations: RoleNavigation.sitter,
        dashboard: const SitterDashboardScreen(),
      ),
      _roleShell(
        role: UserRole.admin,
        destinations: RoleNavigation.admin,
        extras: RoleNavigation.adminExtras,
        dashboard: const AdminDashboardScreen(),
        built: <String, GoRoute>{
          AdminBookingRoutes.list: GoRoute(
            path: AdminBookingRoutes.list,
            builder: (BuildContext context, GoRouterState state) =>
                const AdminBookingListScreen(),
            routes: <RouteBase>[
              GoRoute(
                path: ':${AdminBookingRoutes.detailParam}',
                builder: (BuildContext context, GoRouterState state) =>
                    AdminBookingDetailScreen(
                      bookingId:
                          state.pathParameters[AdminBookingRoutes.detailParam]!,
                    ),
              ),
            ],
          ),
          AdminPawrentRoutes.list: GoRoute(
            path: AdminPawrentRoutes.list,
            builder: (BuildContext context, GoRouterState state) =>
                const AdminPawrentListScreen(),
            routes: <RouteBase>[
              GoRoute(
                path: ':${AdminPawrentRoutes.detailParam}',
                builder: (BuildContext context, GoRouterState state) =>
                    AdminPawrentDetailScreen(
                      ownerId:
                          state.pathParameters[AdminPawrentRoutes.detailParam]!,
                    ),
                routes: <RouteBase>[
                  GoRoute(
                    path:
                        '${AdminPawrentRoutes.bookingSegment}/'
                        ':${AdminBookingRoutes.detailParam}',
                    builder: (BuildContext context, GoRouterState state) {
                      final String ownerId =
                          state.pathParameters[AdminPawrentRoutes.detailParam]!;
                      return AdminBookingDetailScreen(
                        bookingId: state
                            .pathParameters[AdminBookingRoutes.detailParam]!,
                        backLabel: 'Detail pawrent',
                        backRoute: AdminPawrentRoutes.detail(ownerId),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          AdminRoomRoutes.list: GoRoute(
            path: AdminRoomRoutes.list,
            builder: (BuildContext context, GoRouterState state) =>
                const AdminRoomsScreen(),
            routes: <RouteBase>[
              GoRoute(
                path: AdminRoomRoutes.createSegment,
                builder: (BuildContext context, GoRouterState state) =>
                    const AdminRoomFormScreen(),
              ),
              GoRoute(
                path: ':${AdminRoomRoutes.editParam}',
                // Id yang bukan angka jatuh ke -1 agar tampil "tidak
                // ditemukan", bukan diam-diam menjadi form tambah.
                builder: (BuildContext context, GoRouterState state) =>
                    AdminRoomFormScreen(
                      roomId:
                          int.tryParse(
                            state.pathParameters[AdminRoomRoutes.editParam]!,
                          ) ??
                          -1,
                    ),
              ),
            ],
          ),
          AdminManageRoutes.hub: GoRoute(
            path: AdminManageRoutes.hub,
            builder: (BuildContext context, GoRouterState state) =>
                const AdminManageScreen(),
            routes: <RouteBase>[
              GoRoute(
                path: AdminManageRoutes.staffSegment,
                builder: (BuildContext context, GoRouterState state) =>
                    const AdminStaffListScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: AdminManageRoutes.createStaffSegment,
                    builder: (BuildContext context, GoRouterState state) =>
                        const AdminStaffFormScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: AdminManageRoutes.addOnsSegment,
                builder: (BuildContext context, GoRouterState state) =>
                    const AdminManagePendingScreen(
                      title: 'Layanan add-on',
                      summary:
                          'Lihat, tambah, ubah, dan nonaktifkan layanan '
                          'tambahan di luar paket kamar.',
                    ),
              ),
              GoRoute(
                path: AdminManageRoutes.reportSegment,
                builder: (BuildContext context, GoRouterState state) =>
                    const AdminManagePendingScreen(
                      title: 'Laporan hotel',
                      summary:
                          'Omzet, jumlah reservasi, rata-rata lama menginap, '
                          'dan tipe kamar terlaris per periode.',
                    ),
              ),
            ],
          ),
        },
      ),
      GoRoute(
        path: login,
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: register,
        builder: (BuildContext context, GoRouterState state) =>
            const RegisterOwnerScreen(),
      ),
      GoRoute(
        path: registerSitter,
        builder: (BuildContext context, GoRouterState state) =>
            const RegisterSitterScreen(),
      ),
      GoRoute(
        path: forgotPassword,
        builder: (BuildContext context, GoRouterState state) =>
            const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: resetPassword,
        builder: (BuildContext context, GoRouterState state) =>
            ResetPasswordScreen(initialEmail: state.extra as String?),
      ),
      GoRoute(
        path: LegalRoutes.ketentuanLayanan,
        builder: (BuildContext context, GoRouterState state) =>
            const LegalDocumentScreen(
              document: LegalDocuments.ketentuanLayananPenitipan,
            ),
      ),
      GoRoute(
        path: LegalRoutes.kebijakanPrivasi,
        builder: (BuildContext context, GoRouterState state) =>
            const LegalDocumentScreen(
              document: LegalDocuments.kebijakanKasihSayang,
            ),
      ),
    ],
  );

  static ShellRoute _roleShell({
    required UserRole role,
    required List<NavDestination> destinations,
    required Widget dashboard,
    List<NavDestination> extras = const <NavDestination>[],
    Map<String, GoRoute> built = const <String, GoRoute>{},
  }) {
    return ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) =>
          RoleShell(role: role, location: state.uri.path, child: child),
      routes: <RouteBase>[
        GoRoute(
          path: destinations.first.route,
          builder: (BuildContext context, GoRouterState state) => dashboard,
        ),
        for (final NavDestination destination in <NavDestination>[
          ...destinations.skip(1),
          ...extras,
        ])
          // Tujuan yang layarnya sudah dibangun memakai rute dari [built].
          built[destination.route] ??
              GoRoute(
                path: destination.route,
                builder: (BuildContext context, GoRouterState state) =>
                    PlaceholderScreen(
                      title: destination.label,
                      summary: destination.placeholderSummary,
                    ),
              ),
      ],
    );
  }
}
