import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../dashboard/presentation/widgets/pet_avatar.dart';
import '../../domain/entities/staff_account.dart';
import '../admin_manage_routes.dart';
import '../widgets/staff_widgets.dart';

class AdminManageScreen extends StatelessWidget {
  const AdminManageScreen({super.key});

  static const String pendingLabel = 'Belum dibangun';

  @override
  Widget build(BuildContext context) {
    final AuthUser? user = context.watch<AuthNotifier>().user;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenEdge,
        AppSpacing.space24,
        AppSpacing.screenEdge,
        AppSpacing.space32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text('Kelola', style: AppTypography.headlineLg),
              ),
              const SizedBox(height: AppSpacing.space20),
              if (user != null) ...<Widget>[
                _SignedInCard(user: user),
                const SizedBox(height: AppSpacing.space20),
              ],
              AppCard(
                padding: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    children: <Widget>[
                      ManageMenuRow(
                        icon: Icons.badge_rounded,
                        title: 'Akun staf',
                        subtitle: 'Lihat dan buat akun penjaga atau admin',
                        onTap: () => context.go(AdminManageRoutes.staff),
                      ),
                      const Divider(height: 1, color: AppColors.outlineVariant),
                      ManageMenuRow(
                        icon: Icons.room_service_rounded,
                        title: 'Layanan add-on',
                        subtitle: 'Layanan tambahan di luar paket kamar',
                        pendingLabel: pendingLabel,
                        onTap: () => context.go(AdminManageRoutes.addOns),
                      ),
                      const Divider(height: 1, color: AppColors.outlineVariant),
                      ManageMenuRow(
                        icon: Icons.insert_chart_outlined_rounded,
                        title: 'Laporan hotel',
                        subtitle: 'Omzet dan okupansi per periode',
                        pendingLabel: pendingLabel,
                        onTap: () => context.go(AdminManageRoutes.report),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignedInCard extends StatelessWidget {
  const _SignedInCard({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          'Masuk sebagai ${user.name}, ${staffRoleLabel(user.role)}. '
          '${user.email}',
      child: ExcludeSemantics(
        child: AppCard(
          borderRadius: AppRadius.heroAll,
          child: Row(
            children: <Widget>[
              PetAvatar(name: user.name, size: 56),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      user.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headlineSm,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              StaffRoleBadge(role: user.role),
            ],
          ),
        ),
      ),
    );
  }
}
