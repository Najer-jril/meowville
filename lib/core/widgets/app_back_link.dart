import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppBackLink extends StatelessWidget {
  const AppBackLink({super.key, required this.label, required this.onBack});

  final String label;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space8,
        AppSpacing.space8,
        AppSpacing.screenEdge,
        0,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          label: Text(label),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.onSurface,
            textStyle: AppTypography.labelLg,
            minimumSize: const Size(
              AppSpacing.minTapTarget,
              AppSpacing.minTapTarget,
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.controlAll,
            ),
          ),
        ),
      ),
    );
  }
}
