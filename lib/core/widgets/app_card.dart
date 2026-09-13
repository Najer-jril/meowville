import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_elevation.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.color = AppColors.surfaceContainerLowest,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.borderRadius = AppRadius.cardAll,
    this.shadows = AppElevation.elevated,
    this.borderColor = AppColors.outlineVariant,
    this.clipBehavior = Clip.none,
  });

  const AppCard.hero({
    super.key,
    required this.child,
    this.color = AppColors.surfaceContainerLowest,
    this.padding = const EdgeInsets.all(AppSpacing.space20),
    this.borderColor = AppColors.outlineVariant,
    this.clipBehavior = Clip.none,
  }) : borderRadius = AppRadius.heroAll,
       shadows = AppElevation.floating;

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final List<BoxShadow> shadows;
  final Color? borderColor;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        boxShadow: shadows,
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: child,
    );
  }
}
