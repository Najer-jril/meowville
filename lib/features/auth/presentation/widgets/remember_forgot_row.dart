import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_checkbox.dart';
import '../../../../core/widgets/app_inline_link.dart';

class RememberForgotRow extends StatelessWidget {
  const RememberForgotRow({
    super.key,
    required this.rememberMe,
    required this.onRememberChanged,
    required this.onForgotPassword,
    required this.enabled,
  });

  final bool rememberMe;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onForgotPassword;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    const double checkboxInset = (AppSpacing.minTapTarget - 16) / 2;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Transform.translate(
          offset: const Offset(-checkboxInset, 0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? () => onRememberChanged(!rememberMe) : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppCheckbox(
                  value: rememberMe,
                  onChanged: onRememberChanged,
                  semanticLabel: 'Ingat Saya',
                  size: 16,
                  enabled: enabled,
                ),
                Flexible(
                  child: Text(
                    'Ingat Saya',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        AppInlineLink(
          text: 'Lupa Kata Sandi?',
          onTap: onForgotPassword,
          style: AppTypography.labelMd,
        ),
      ],
    );
  }
}
