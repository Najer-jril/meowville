import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/data.dart';
import '../../data/models.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';

class SitterAccountScreen extends StatelessWidget {
  const SitterAccountScreen({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AdminStore>();
    final text = Theme.of(context).textTheme;

    final watching = store.staying.length;
    final myReports = store.reports
        .where(
          (d) =>
              d.reporter == user &&
              d.time.year == store.today.year &&
              d.time.month == store.today.month &&
              d.time.day == store.today.day,
        )
        .length;

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
                          style: text.bodySmall!.copyWith(fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.call_outlined,
                              size: 16,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                user.phone,
                                style: text.bodySmall!.copyWith(fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  StatusBadge.role(user.role.key),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              color: AppColors.primarySoft,
              shadow: false,
              child: Row(
                children: [
                  const IconBubble(
                    icon: Icons.pets,
                    color: Colors.white,
                    background: AppColors.primary,
                    square: true,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status piket aktif',
                          style: text.labelLarge!.copyWith(
                            color: AppColors.primaryDeep,
                          ),
                        ),
                        Text(
                          '$watching kucing dalam pantauan - '
                          '$myReports laporan kamu hari ini',
                          style: text.bodySmall!.copyWith(
                            fontSize: 14,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                      ],
                    ),
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
                  Expanded(
                    child: Text(
                      'Keluar',
                      style: text.labelLarge!.copyWith(
                        fontSize: 18,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.danger),
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
