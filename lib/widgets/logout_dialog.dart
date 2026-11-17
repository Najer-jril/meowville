import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../routes/app_routes.dart';
import 'common.dart';

/// Logout confirmation shared by the admin, sitter, and owner account pages.
Future<void> confirmLogout(BuildContext context) async {
  final ok = await showConfirmDialog(
    context,
    title: 'Keluar dari akun?',
    message: 'Anda perlu masuk lagi untuk mengakses Meowville.',
    confirmLabel: 'Keluar',
    destructive: true,
    icon: Icons.logout,
  );
  if (!ok || !context.mounted) return;
  await context.read<AuthController>().signOut();
  if (context.mounted) {
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }
}
