import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

class SummaryStatCard extends StatelessWidget {
  const SummaryStatCard({
    super.key,
    required this.label,
    required this.value,
    this.detail,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final String? detail;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final Color foreground = emphasis
        ? AppColors.brandTerracottaPressed
        : AppColors.onSurface;
    final Color secondary = emphasis
        ? AppColors.brandTerracottaPressed
        : AppColors.onSurfaceVariant;

    return Semantics(
      container: true,
      label: '$label: $value${detail == null ? '' : ', $detail'}',
      excludeSemantics: true,
      child: AppCard(
        color: emphasis
            ? AppColors.badgeStayingSurface
            : AppColors.surfaceContainerLowest,
        borderColor: emphasis ? AppColors.badgeStayingSurface : null,
        shadows: const <BoxShadow>[],
        borderRadius: AppRadius.cardAll,
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: AppTypography.labelMd.copyWith(color: secondary),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              value,
              style: AppTypography.headlineLg.copyWith(color: foreground),
            ),
            if (detail != null) ...<Widget>[
              const SizedBox(height: AppSpacing.space2),
              Text(
                detail!,
                style: AppTypography.caption.copyWith(color: secondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SummaryGrid extends StatelessWidget {
  const SummaryGrid({super.key, required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double gap = AppSpacing.space12;
        final double width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (final Widget card in cards)
              SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }
}
