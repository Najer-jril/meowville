import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppHelperNote extends StatelessWidget {
  const AppHelperNote({super.key, required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 15, color: AppColors.brandTerracotta),
          ),
        ),
        const SizedBox(width: AppSpacing.space4),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
