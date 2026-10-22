import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/data.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';

class OwnerAccountScreen extends StatelessWidget {
  const OwnerAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AdminStore>();
    final text = Theme.of(context).textTheme;

    final user = store.currentOwner;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.xl,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          children: [
            Text('Akun', style: text.headlineLarge),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.ownerProfileForm,
                arguments: user,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(
                    initial: user.initial,
                    photo: user.photo,
                    size: 64,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: text.titleLarge!.copyWith(fontSize: 20),
                        ),
                        Text(
                          user.email,
                          style: text.bodySmall!.copyWith(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.phone,
                          style: text.bodySmall!.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _MenuTile(
                    icon: Icons.person_outline,
                    title: 'Edit profil',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.ownerProfileForm,
                      arguments: user,
                    ),
                  ),
                  const Divider(
                    indent: AppSpacing.page,
                    endIndent: AppSpacing.page,
                  ),
                  _MenuTile(
                    icon: Icons.policy_outlined,
                    title: 'Kebijakan Meowville',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.policy),
                  ),
                  const Divider(
                    indent: AppSpacing.page,
                    endIndent: AppSpacing.page,
                  ),
                  _MenuTile(
                    icon: Icons.gavel_outlined,
                    title: 'Ketentuan layanan',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.legal),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.page),
              onTap: () => _confirmLogout(context),
              child: Row(
                children: [
                  const Icon(Icons.logout, color: AppColors.danger),
                  const SizedBox(width: AppSpacing.lg),
                  Text(
                    'Keluar',
                    style: text.labelLarge!.copyWith(
                      fontSize: 18,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Keluar dari akun?',
      message: 'Anda perlu masuk lagi untuk mengakses Meowville.',
      confirmLabel: 'Keluar',
      destructive: true,
      icon: Icons.logout,
    );
    if (ok && context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    }
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.page,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            IconBubble(icon: icon, size: 44),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelLarge!
                    .copyWith(fontSize: 17),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
