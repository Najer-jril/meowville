import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/legal_routes.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_owner_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/legal/data/legal_documents.dart';
import '../../features/legal/presentation/screens/legal_document_screen.dart';
import '../../features/splash/presentation/screens/session_check_screen.dart';

class AppRouter {
  AppRouter(this.authNotifier);

  final AuthNotifier authNotifier;

  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String sessionCheck = '/memeriksa-sesi';

  late final GoRouter router = GoRouter(
    refreshListenable: authNotifier,
    initialLocation: sessionCheck,
    redirect: (BuildContext context, GoRouterState state) {
      final String location = state.matchedLocation;

      if (authNotifier.isChecking) {
        return location == sessionCheck ? null : sessionCheck;
      }

      final bool signedIn = authNotifier.isAuthenticated;
      final bool onAuthScreen = location == login || location == register;
      final bool onPublicScreen =
          onAuthScreen || LegalRoutes.coversLocation(location);

      if (!signedIn) {
        return onPublicScreen ? null : login;
      }

      if (onAuthScreen || location == sessionCheck) {
        return home;
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
            const HomeScreen(),
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
