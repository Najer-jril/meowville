import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/legal_routes.dart';
import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_owner_screen.dart';
import '../../features/auth/presentation/screens/register_sitter_screen.dart';
import '../../features/home/presentation/role_home_config.dart';
import '../../features/home/presentation/screens/admin_home_screen.dart';
import '../../features/home/presentation/screens/owner_home_screen.dart';
import '../../features/home/presentation/screens/sitter_home_screen.dart';
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
  static const String sessionCheck = '/memeriksa-sesi';

  static const String ownerHome = RoleHomeConfig.ownerRoute;
  static const String sitterHome = RoleHomeConfig.sitterRoute;
  static const String adminHome = RoleHomeConfig.adminRoute;

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
          location == registerSitter;
      final bool onPublicScreen =
          onAuthScreen || LegalRoutes.coversLocation(location);

      final AuthUser? user = authNotifier.user;
      if (user == null) {
        return onPublicScreen ? null : login;
      }

      final String roleHome = RoleHomeConfig.forRole(user.role).route;

      if (onAuthScreen || location == sessionCheck || location == home) {
        return roleHome;
      }
      if (RoleHomeConfig.isRoleRoute(location) && location != roleHome) {
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
      GoRoute(
        path: ownerHome,
        builder: (BuildContext context, GoRouterState state) =>
            const OwnerHomeScreen(),
      ),
      GoRoute(
        path: sitterHome,
        builder: (BuildContext context, GoRouterState state) =>
            const SitterHomeScreen(),
      ),
      GoRoute(
        path: adminHome,
        builder: (BuildContext context, GoRouterState state) =>
            const AdminHomeScreen(),
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
}
