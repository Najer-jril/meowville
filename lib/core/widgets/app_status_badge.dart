import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppStatusTone {
  menunggu,
  disetujui,
  ditolak,
  menginap,
  selesai,
  dibatalkan,
}

extension AppStatusToneX on AppStatusTone {
  Color get surface => switch (this) {
    AppStatusTone.menunggu => AppColors.pendingSurface,
    AppStatusTone.disetujui => AppColors.successSurface,
    AppStatusTone.ditolak => AppColors.errorContainer,
    AppStatusTone.menginap => AppColors.badgeStayingSurface,
    AppStatusTone.selesai => AppColors.badgeDoneSurface,
    AppStatusTone.dibatalkan => AppColors.badgeCancelledSurface,
  };

  Color get foreground => switch (this) {
    AppStatusTone.menunggu => AppColors.pendingText,
    AppStatusTone.disetujui => AppColors.successText,
    AppStatusTone.ditolak => AppColors.onErrorContainer,
    AppStatusTone.menginap => AppColors.badgeStayingText,
    AppStatusTone.selesai => AppColors.badgeDoneText,
    AppStatusTone.dibatalkan => AppColors.badgeCancelledText,
  };
}

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({super.key, required this.label, required this.tone});

  final String label;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space8,
        vertical: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        label,
        style: AppTypography.labelMd.copyWith(color: tone.foreground),
      ),
    );
  }
}
