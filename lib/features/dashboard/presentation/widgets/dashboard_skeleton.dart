import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({
    super.key,
    required this.label,
    this.blockHeights = const <double>[148, 96, 96],
  });

  final String label;
  final List<double> blockHeights;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: label,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenEdge,
          AppSpacing.space24,
          AppSpacing.screenEdge,
          AppSpacing.space24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const _Bar(width: 180, height: 26),
                const SizedBox(height: AppSpacing.space8),
                const _Bar(width: 240, height: 14),
                const SizedBox(height: AppSpacing.space24),
                for (final double height in blockHeights) ...<Widget>[
                  _Block(height: height),
                  const SizedBox(height: AppSpacing.space16),
                ],
                ExcludeSemantics(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
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

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: AppRadius.baseAll,
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: AppColors.outlineVariant),
      ),
    );
  }
}
