import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_elevation.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/pending_feature_sheet.dart';
import '../../../../core/widgets/staggered_entrance.dart';
import '../../../../core/widgets/village_skyline.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/widgets/meowville_logo_badge.dart';
import '../role_home_config.dart';

class RoleHomeScaffold extends StatefulWidget {
  const RoleHomeScaffold({super.key, required this.config});

  final RoleHomeConfig config;

  @override
  State<RoleHomeScaffold> createState() => _RoleHomeScaffoldState();
}

class _RoleHomeScaffoldState extends State<RoleHomeScaffold> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    if (_signingOut) {
      return;
    }
    setState(() => _signingOut = true);
    try {
      await context.read<AuthNotifier>().signOut();
    } on AppException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _signingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), duration: const Duration(seconds: 5)),
      );
    }
  }

  void _openPending(UpcomingArea area) {
    showPendingFeatureSheet(
      context,
      title: area.title,
      description:
          '${area.summary} Bagian ini belum dibangun, jadi belum ada data '
          'yang bisa ditampilkan di sini.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final RoleHomeConfig config = widget.config;
    final AuthUser? user = context.watch<AuthNotifier>().user;
    final String greeting = user == null
        ? 'Halo'
        : 'Halo, ${user.name.split(' ').first}';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _HomeTopBar(signingOut: _signingOut, onSignOut: _signOut),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenEdge,
                  AppSpacing.space24,
                  AppSpacing.screenEdge,
                  AppSpacing.space32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: StaggeredEntrance(
                      children: <Widget>[
                        _RoleChip(config: config),
                        const SizedBox(height: AppSpacing.space12),
                        Semantics(
                          header: true,
                          child: Text(
                            greeting,
                            style: AppTypography.headlineLg,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space8),
                        Text(
                          config.intent,
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space32),
                        Semantics(
                          header: true,
                          child: Text(
                            'Yang sedang disiapkan',
                            style: AppTypography.headlineSm,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space4),
                        Text(
                          'Ketuk salah satu untuk membaca rencananya.',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space16),
                        for (final UpcomingArea area in config.upcoming) ...<Widget>[
                          _UpcomingCard(
                            area: area,
                            onTap: () => _openPending(area),
                          ),
                          const SizedBox(height: AppSpacing.space12),
                        ],
                        const SizedBox(height: AppSpacing.space20),
                        const VillageSkyline(
                          height: 56,
                          houseColor: AppColors.surfaceContainerHigh,
                          windowColor: AppColors.surface,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.signingOut, required this.onSignOut});

  final bool signingOut;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: AppElevation.topBar,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: SizedBox(
        height: AppSpacing.topBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdge,
          ),
          child: Row(
            children: <Widget>[
              const MeowvilleLogoBadge(diameter: 32),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: Text(
                  'Meowville',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headlineSm,
                ),
              ),
              _SignOutButton(signingOut: signingOut, onPressed: onSignOut),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.signingOut, required this.onPressed});

  final bool signingOut;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.controlAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: signingOut ? null : onPressed,
        borderRadius: AppRadius.controlAll,
        hoverColor: AppColors.surfaceContainer,
        highlightColor: AppColors.surfaceRecessed,
        focusColor: AppColors.surfaceRecessed,
        child: Tooltip(
          message: 'Keluar akun',
          child: SizedBox(
            width: AppSpacing.minTapTarget,
            height: AppSpacing.minTapTarget,
            child: Semantics(
              button: true,
              enabled: !signingOut,
              label: signingOut ? 'Sedang keluar akun' : 'Keluar akun',
              child: Center(
                child: signingOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onSurfaceVariant,
                        ),
                      )
                    : const Icon(
                        Icons.logout_rounded,
                        size: 22,
                        color: AppColors.onSurface,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.config});

  final RoleHomeConfig config;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space12,
          vertical: AppSpacing.space4 + 2,
        ),
        decoration: BoxDecoration(
          color: config.accentSurface,
          borderRadius: AppRadius.pillAll,
        ),
        child: Text(
          config.roleLabel,
          style: AppTypography.labelMd.copyWith(color: config.accentText),
        ),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.area, required this.onTap});

  final UpcomingArea area;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.cardAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardAll,
        hoverColor: AppColors.surfaceContainer,
        highlightColor: AppColors.surfaceRecessed,
        focusColor: AppColors.surfaceRecessed,
        child: Semantics(
          button: true,
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(area.title, style: AppTypography.labelLg),
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    const _PendingChip(),
                  ],
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  area.summary,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingChip extends StatelessWidget {
  const _PendingChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space8,
        vertical: AppSpacing.space2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        'Belum dibangun',
        style: AppTypography.caption.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
