import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel({
    super.key,
    required this.text,
    this.icon,
    this.hint,
    this.color = AppColors.onSurface,
    this.style,
  });

  final String text;
  final IconData? icon;
  final String? hint;
  final Color color;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final Widget label = Text(
      text,
      style: (style ?? AppTypography.labelLg).copyWith(color: color),
    );

    if (icon == null && hint == null) {
      return label;
    }

    return Row(
      children: <Widget>[
        if (icon != null) ...<Widget>[
          ExcludeSemantics(
            child: Icon(icon, size: 18, color: AppColors.brandTerracotta),
          ),
          const SizedBox(width: AppSpacing.space8),
        ],
        Flexible(child: label),
        if (hint != null) ...<Widget>[
          const SizedBox(width: AppSpacing.space8),
          Expanded(
            child: Text(
              hint!,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
