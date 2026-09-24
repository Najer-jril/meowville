import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_elevation.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'nav_destination.dart';

class RoleBottomNav extends StatelessWidget {
  const RoleBottomNav({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
  });

  static const double barHeight = 64;
  static const double actionLift = 14;

  final List<NavDestination> destinations;
  final int currentIndex;
  final ValueChanged<NavDestination> onSelected;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final bool hasAction = destinations.any(
      (NavDestination d) => d.isPrimaryAction,
    );
    final double lift = hasAction ? actionLift : 0;

    // Label bar dijaga di skala teks sedang supaya lima tab tetap muat.
    final MediaQueryData media = MediaQuery.of(context);
    final TextScaler clamped = media.textScaler.clamp(maxScaleFactor: 1.15);

    return MediaQuery(
      data: media.copyWith(textScaler: clamped),
      child: SizedBox(
        height: barHeight + lift + bottomInset,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: barHeight + bottomInset,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  boxShadow: AppElevation.bottomNav,
                  border: Border(
                    top: BorderSide(color: AppColors.outlineVariant),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  for (int i = 0; i < destinations.length; i++)
                    Expanded(
                      child: destinations[i].isPrimaryAction
                          ? _ActionItem(
                              destination: destinations[i],
                              selected: i == currentIndex,
                              onTap: () => onSelected(destinations[i]),
                            )
                          : _TabItem(
                              destination: destinations[i],
                              selected: i == currentIndex,
                              onTap: () => onSelected(destinations[i]),
                            ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected
        ? AppColors.brandTerracottaPressed
        : AppColors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.controlAll,
          hoverColor: AppColors.surfaceContainer,
          focusColor: AppColors.surfaceRecessed,
          child: SizedBox(
            height: RoleBottomNav.barHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 52,
                  height: 30,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.badgeStayingSurface
                        : Colors.transparent,
                    borderRadius: AppRadius.pillAll,
                  ),
                  child: Icon(destination.icon, size: 22, color: color),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  static const double _diameter = 52;

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.controlAll,
          hoverColor: AppColors.surfaceContainer,
          focusColor: AppColors.surfaceRecessed,
          child: SizedBox(
            height: RoleBottomNav.barHeight + RoleBottomNav.actionLift,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Container(
                  width: _diameter,
                  height: _diameter,
                  decoration: BoxDecoration(
                    color: AppColors.primaryStrong,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? AppColors.brandTerracottaEdge
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: AppElevation.elevated,
                  ),
                  child: Icon(
                    destination.icon,
                    size: 26,
                    color: AppColors.onPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  destination.label,
                  maxLines: 1,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.brandTerracottaPressed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
