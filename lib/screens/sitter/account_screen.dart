import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/daily_report_controller.dart';
import '../../controllers/reservation_controller.dart';
import '../../data/models.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';
import '../../widgets/account_dialogs.dart';

class SitterAccountScreen extends StatelessWidget {
  const SitterAccountScreen({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final account = context.watch<AuthController>().user ?? user;

    final watching = context.watch<ReservationController>().staying.length;
    final myReports = context.watch<DailyReportController>().countToday(
      account,
    );

    Widget action(
      IconData icon,
      String label,
      VoidCallback onTap, {
      Color color = AppColors.primaryDeep,
    }) => AppCard(
      padding: const EdgeInsets.all(AppSpacing.page),
      onTap: onTap,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: Icon(icon, color: color),
          ),
          Expanded(
            child: Text(
              label,
              style: text.labelLarge!.copyWith(fontSize: 18, color: color),
            ),
          ),
          Icon(Icons.chevron_right, color: color),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.xl,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          child: Column(
            spacing: AppSpacing.lg,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Akun', style: text.headlineLarge),
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.lg),
                      child: UserAvatar(
                        initial: account.initial,
                        photo: account.photo,
                        size: 64,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: text.titleLarge!.copyWith(fontSize: 20),
                          ),
                          Text(
                            account.email,
                            style: text.bodySmall!.copyWith(fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Row(
                              spacing: AppSpacing.sm,
                              children: [
                                const Icon(
                                  Icons.call_outlined,
                                  size: 16,
                                  color: AppColors.muted,
                                ),
                                Flexible(
                                  child: Text(
                                    account.phone,
                                    style: text.bodySmall!.copyWith(
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge.role(account.role.key),
                  ],
                ),
              ),
              AppCard(
                color: AppColors.primarySoft,
                shadow: false,
                child: Row(
                  spacing: AppSpacing.lg,
                  children: [
                    const IconBubble(
                      icon: Icons.pets,
                      color: Colors.white,
                      background: AppColors.primary,
                      square: true,
                    ),
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
              action(
                Icons.person_outline,
                'Edit profil',
                () => Navigator.pushNamed(
                  context,
                  AppRoutes.ownerProfileForm,
                  arguments: account,
                ),
              ),
              action(
                Icons.delete_forever_outlined,
                'Hapus akun',
                () => confirmDeleteAccount(context),
                color: AppColors.danger,
              ),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.page),
                onTap: () => confirmLogout(context),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: AppSpacing.lg),
                      child: Icon(Icons.logout, color: AppColors.danger),
                    ),
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
      ),
    );
  }
}
