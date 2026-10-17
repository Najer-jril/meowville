import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/registration_screen.dart';
import '../screens/auth/policy_screen.dart';
import '../screens/auth/legal_screen.dart';

import '../screens/admin/admin_shell.dart';

import '../screens/sitter/sitter_shell.dart';

import '../screens/owner/owner_shell.dart';

import '../screens/splash_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const policy = '/policy';
  static const legal = '/legal';

  static const adminHome = '/admin';
  
  static const sitterHome = '/sitter';
  
  static const ownerHome = '/owner';
  
  static Route<dynamic> generate(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      splash => const SplashScreen(),
      login => const LoginScreen(),
      register => const RegistrationScreen(),
      forgotPassword => const ForgotPasswordScreen(),
      policy => const PolicyScreen(),
      legal => const LegalScreen(),
      adminHome => const AdminShell(),
      sitterHome => const SitterShell(),
      ownerHome => const OwnerShell(),
      _ => const _NotFoundScreen(),
    };
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('404', style: text.headlineLarge),
            const SizedBox(height: AppSpacing.sm),
            Text('Halaman tidak ditemukan', style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}
