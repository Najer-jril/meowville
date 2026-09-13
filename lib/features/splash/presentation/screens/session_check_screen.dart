import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/widgets/meowville_logo_badge.dart';

class SessionCheckScreen extends StatelessWidget {
  const SessionCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenEdge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const MeowvilleLogoBadge(),
              const SizedBox(height: AppSpacing.space16),
              Text(
                'Memeriksa sesi Anda',
                style: AppTypography.headlineSm,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'Sebentar, kami sedang membaca data masuk yang tersimpan.',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space20),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
