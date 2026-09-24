import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';

class TapCard extends StatelessWidget {
  const TapCard({
    super.key,
    required this.onTap,
    required this.child,
    this.padding,
    this.semanticLabel,
    this.showChevron = false,
  });

  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final Widget content = showChevron
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(child: child),
              const SizedBox(width: AppSpacing.space8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.onSurfaceMuted,
              ),
            ],
          )
        : child;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.cardAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardAll,
          hoverColor: AppColors.surfaceContainer,
          highlightColor: AppColors.surfaceRecessed,
          focusColor: AppColors.surfaceRecessed,
          child: padding == null
              ? AppCard(child: content)
              : AppCard(padding: padding!, child: content),
        ),
      ),
    );
  }
}
