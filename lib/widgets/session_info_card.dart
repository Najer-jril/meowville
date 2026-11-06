import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../data/models.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'common.dart';

/// Shows what the login stored: who the token belongs to, when it expires,
/// and whether it is kept on the device.
class SessionInfoCard extends StatelessWidget {
  const SessionInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final session = auth.session;
    final user = auth.user;
    if (session == null || user == null) return const SizedBox.shrink();

    final text = Theme.of(context).textTheme;
    final token = session.accessToken;
    final expires = session.expiresAt;
    String two(int n) => n.toString().padLeft(2, '0');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Info Sesi', style: text.labelLarge!.copyWith(fontSize: 17)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Row(label: 'User ID', value: session.userId),
          _Row(label: 'Email', value: session.email),
          _Row(label: 'Peran', value: user.role.key),
          _Row(
            label: 'Token berlaku s/d',
            value:
                '${Fmt.date(expires)} '
                '${two(expires.hour)}:${two(expires.minute)}',
          ),
          _Row(
            label: 'Access token',
            value: '${token.substring(0, 24)}…',
            mono: true,
          ),
          _Row(
            label: 'Disimpan di perangkat',
            value: auth.remembered ? 'Ya (Ingat saya)' : 'Tidak',
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final caption = Theme.of(context).textTheme.bodySmall!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: caption.copyWith(color: AppColors.muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: mono ? caption.copyWith(fontFamily: 'monospace') : caption,
            ),
          ),
        ],
      ),
    );
  }
}

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
