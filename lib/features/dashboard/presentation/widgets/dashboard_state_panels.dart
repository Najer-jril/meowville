import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';

class DashboardErrorPanel extends StatelessWidget {
  const DashboardErrorPanel({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'Dashboard belum bisa dimuat',
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenEdge + 4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const _PanelIcon(
                  icon: Icons.cloud_off_rounded,
                  background: AppColors.errorContainer,
                  foreground: AppColors.onErrorContainer,
                ),
                const SizedBox(height: AppSpacing.space12),
                Semantics(
                  liveRegion: true,
                  header: true,
                  child: Text(title, style: AppTypography.headlineSm),
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  message,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
                AppPrimaryButton(label: 'Coba Lagi', onPressed: onRetry),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardEmptyPanel extends StatelessWidget {
  const DashboardEmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(
        compact ? AppSpacing.space16 : AppSpacing.space20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (!compact) ...<Widget>[
            _PanelIcon(
              icon: icon,
              background: AppColors.surfaceContainerHigh,
              foreground: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.space12),
          ],
          Text(title, style: AppTypography.labelLg),
          const SizedBox(height: AppSpacing.space4),
          Text(
            message,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: AppSpacing.space16),
            AppSecondaryButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

class _PanelIcon extends StatelessWidget {
  const _PanelIcon({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ExcludeSemantics(
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadius.controlAll,
          ),
          child: Icon(icon, size: 22, color: foreground),
        ),
      ),
    );
  }
}
