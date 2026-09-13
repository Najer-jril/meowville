import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.space12),
        decoration: BoxDecoration(
          color: AppColors.errorContainer,
          borderRadius: AppRadius.lgAll,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(
              Icons.report_gmailerrorred_outlined,
              size: 18,
              color: AppColors.onErrorContainer,
            ),
            const SizedBox(width: AppSpacing.space8),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
