import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_elevation.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.topBarHeight);

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.paddingOf(context).top;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: AppElevation.topBar,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: topInset),
        child: SizedBox(
          height: AppSpacing.topBarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenEdge,
            ),
            child: Row(
              children: <Widget>[
                if (onBack != null) ...<Widget>[
                  _BackButton(onPressed: onBack!),
                  const SizedBox(width: AppSpacing.space8),
                ],
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headlineSm,
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

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.controlAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.controlAll,
        hoverColor: AppColors.surfaceContainer,
        highlightColor: AppColors.surfaceRecessed,
        focusColor: AppColors.surfaceRecessed,
        child: Tooltip(
          message: 'Kembali',
          child: SizedBox(
            width: AppSpacing.minTapTarget,
            height: AppSpacing.minTapTarget,
            child: Semantics(
              button: true,
              label: 'Kembali',
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 22,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
