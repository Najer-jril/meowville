import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/relative_date.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../dashboard/presentation/widgets/pet_avatar.dart';
import '../../domain/entities/staff_account.dart';

class StaffRoleBadge extends StatelessWidget {
  const StaffRoleBadge({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = role == UserRole.admin;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space8,
        vertical: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: isAdmin ? AppColors.primarySoft : AppColors.successSurface,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        staffRoleLabel(role),
        style: AppTypography.labelMd.copyWith(
          color: isAdmin
              ? AppColors.brandTerracottaPressed
              : AppColors.successText,
        ),
      ),
    );
  }
}

class StaffAccountCard extends StatelessWidget {
  const StaffAccountCard({
    super.key,
    required this.account,
    this.isCurrentUser = false,
  });

  final StaffAccount account;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final String created = 'Dibuat ${formatShortDate(account.createdAt)}';
    final String role = staffRoleLabel(account.role);

    return Semantics(
      container: true,
      label:
          '${account.name}${isCurrentUser ? ', akun Anda' : ''}, $role. '
          '${account.email}. $created.',
      child: ExcludeSemantics(
        child: AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              PetAvatar(name: account.name),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            account.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headlineSm,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space8),
                        StaffRoleBadge(role: account.role),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      account.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMd,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      isCurrentUser ? '$created · Akun Anda' : created,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
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

class RoleOptionCard extends StatelessWidget {
  const RoleOptionCard({
    super.key,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: '$title. $description',
      child: ExcludeSemantics(
        child: Material(
          color: AppColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.cardAll,
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            hoverColor: AppColors.surfaceContainer,
            focusColor: AppColors.surfaceRecessed,
            highlightColor: AppColors.surfaceRecessed,
            child: Padding(
              // Garis tepi 2 px saat terpilih dipotong dari padding agar
              // kartu tidak melonjak tingginya.
              padding: EdgeInsets.all(
                AppSpacing.cardPadding - (selected ? 1 : 0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 22,
                      color: selected
                          ? AppColors.brandTerracottaDark
                          : AppColors.outline,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(title, style: AppTypography.labelLg),
                        const SizedBox(height: AppSpacing.space2),
                        Text(
                          description,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ManageMenuRow extends StatelessWidget {
  const ManageMenuRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.pendingLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? pendingLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          '$title. $subtitle${pendingLabel == null ? '' : '. $pendingLabel'}',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          hoverColor: AppColors.surfaceContainer,
          focusColor: AppColors.surfaceRecessed,
          highlightColor: AppColors.surfaceRecessed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.cardPadding,
                vertical: AppSpacing.space12,
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceRecessed,
                      borderRadius: AppRadius.controlAll,
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: AppColors.brandTerracottaDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(title, style: AppTypography.headlineSm),
                        const SizedBox(height: AppSpacing.space2),
                        Text(
                          subtitle,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        if (pendingLabel != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.space4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.space8,
                              vertical: AppSpacing.space2,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: AppRadius.pillAll,
                            ),
                            child: Text(
                              pendingLabel!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
