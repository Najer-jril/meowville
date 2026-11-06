import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../data/data.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';
import '../../widgets/session_info_card.dart';

class SitterAccountScreen extends StatelessWidget {
  const SitterAccountScreen({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AdminStore>();
    final text = Theme.of(context).textTheme;
    final account = context.watch<AuthController>().user ?? user;

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
                    initial: account.initial,
                    photo: account.photo,
                    size: 64,
                  ),
                  const SizedBox(width: AppSpacing.lg),
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
                                account.phone,
                                style: text.bodySmall!.copyWith(fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  StatusBadge.role(account.role.key),
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
            const SessionInfoCard(),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.page),
              onTap: () => confirmLogout(context),
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
}
