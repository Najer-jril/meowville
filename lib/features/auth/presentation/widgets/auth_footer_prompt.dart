import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_inline_link.dart';

class AuthFooterPrompt extends StatelessWidget {
  const AuthFooterPrompt({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.onAction,
    this.linkColor = AppColors.primaryContainer,
  });

  final String question;
  final String actionLabel;
  final VoidCallback onAction;
  final Color linkColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.space4,
      runSpacing: AppSpacing.space4,
      children: <Widget>[
        Text(
          question,
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        AppInlineLink(
          text: actionLabel,
          onTap: onAction,
          color: linkColor,
          style: AppTypography.labelLg,
        ),
      ],
    );
  }
}
