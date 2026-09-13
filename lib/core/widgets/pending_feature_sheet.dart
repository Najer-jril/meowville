import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

Future<void> showPendingFeatureSheet(
  BuildContext context, {
  required String title,
  required String description,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceContainerLowest,
    barrierColor: AppColors.brandCharcoal.withValues(alpha: 0.4),
    showDragHandle: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
    ),
    builder: (BuildContext sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenEdge,
          0,
          AppSpacing.screenEdge,
          AppSpacing.space24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title, style: AppTypography.headlineSm),
            const SizedBox(height: AppSpacing.space8),
            Text(
              description,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandTerracottaDark,
                  textStyle: AppTypography.labelLg,
                  minimumSize: const Size(
                    AppSpacing.minTapTarget,
                    AppSpacing.minTapTarget,
                  ),
                ),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      );
    },
  );
}
