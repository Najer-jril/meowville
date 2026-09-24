import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/staggered_entrance.dart';
import '../../../../core/widgets/village_skyline.dart';
import 'meowville_logo_badge.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.panelStatement,
    required this.form,
    required this.footer,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  final String panelStatement;
  final Widget form;
  final Widget footer;

  static const double _wideBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= _wideBreakpoint;
          final Widget formColumn = _FormColumn(
            eyebrow: eyebrow,
            title: title,
            subtitle: subtitle,
            form: form,
            footer: footer,
            showBrand: !wide,
          );

          if (!wide) {
            return SafeArea(child: formColumn);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                flex: 5,
                child: _VillagePanel(statement: panelStatement),
              ),
              Expanded(
                flex: 6,
                child: SafeArea(left: false, child: formColumn),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FormColumn extends StatelessWidget {
  const _FormColumn({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.form,
    required this.footer,
    required this.showBrand,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget form;
  final Widget footer;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdge + 4,
            AppSpacing.space24,
            AppSpacing.screenEdge + 4,
            AppSpacing.space32,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - AppSpacing.space24 * 2,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: StaggeredEntrance(
                  children: <Widget>[
                    if (showBrand) ...<Widget>[
                      const _BrandRow(),
                      const SizedBox(height: AppSpacing.space32),
                    ],
                    Text(
                      eyebrow.toUpperCase(),
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.brandTerracottaDark,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Semantics(
                      header: true,
                      child: Text(title, style: AppTypography.headlineLg),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Text(
                        subtitle,
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.55,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    const VillageSkyline(
                      height: 52,
                      houseColor: AppColors.surfaceContainerHigh,
                      windowColor: AppColors.surface,
                    ),
                    AppCard.hero(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.space20,
                        AppSpacing.space24,
                        AppSpacing.space20,
                        AppSpacing.space20,
                      ),
                      child: form,
                    ),
                    const SizedBox(height: AppSpacing.space24),
                    footer,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const MeowvilleLogoBadge(diameter: 44),
        const SizedBox(width: AppSpacing.space12),
        Flexible(child: Text('Meowville', style: AppTypography.headlineMd)),
      ],
    );
  }
}

class _VillagePanel extends StatelessWidget {
  const _VillagePanel({required this.statement});

  final String statement;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.darkSurface,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space48,
            AppSpacing.space40,
            AppSpacing.space48,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const MeowvilleLogoBadge(diameter: 44),
                  const SizedBox(width: AppSpacing.space12),
                  Text(
                    'Meowville',
                    style: AppTypography.headlineMd.copyWith(
                      color: AppColors.brandCream,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  statement,
                  style: AppTypography.display.copyWith(
                    color: AppColors.brandCream,
                    fontSize: 36,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
              Text(
                'Penitipan kucing dengan kabar harian.',
                style: AppTypography.bodyLg.copyWith(
                  color: AppColors.darkMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.space40),
              const VillageSkyline(
                height: 120,
                alignRight: false,
                houseColor: AppColors.darkCard,
                windowColor: AppColors.brandTerracottaLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
