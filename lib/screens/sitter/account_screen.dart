import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../data/data.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';
import '../../widgets/logout_dialog.dart';

class SitterAccountScreen extends StatelessWidget {
  const SitterAccountScreen({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AdminStore>();
    final text = Theme.of(context).textTheme;
    final auth = context.watch<AuthController>();
    final account = auth.user ?? user;

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
