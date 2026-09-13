import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_checkbox.dart';

class TermsConsentRow extends StatelessWidget {
  const TermsConsentRow({
    super.key,
    required this.accepted,
    required this.onChanged,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
    required this.enabled,
    this.errorText,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final TextStyle body = AppTypography.bodySm.copyWith(
      color: AppColors.onSurface,
    );
    final TextStyle link = AppTypography.bodySm.copyWith(
      color: AppColors.brandTerracottaDark,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.brandTerracottaDark,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppCheckbox(
              value: accepted,
              onChanged: onChanged,
              semanticLabel:
                  'Saya menyetujui ketentuan layanan dan kebijakan '
                  'kasih sayang Meowville',
              enabled: enabled,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.space12),
                child: Text.rich(
                  TextSpan(
                    style: body,
                    children: <InlineSpan>[
                      const TextSpan(text: 'Saya menyetujui '),
                      TextSpan(
                        text: 'Ketentuan Layanan Penitipan',
                        style: link,
                        recognizer: TapGestureRecognizer()
                          ..onTap = enabled ? onOpenTerms : null,
                      ),
                      const TextSpan(text: ' & '),
                      TextSpan(
                        text: 'Kebijakan Kasih Sayang',
                        style: link,
                        recognizer: TapGestureRecognizer()
                          ..onTap = enabled ? onOpenPrivacy : null,
                      ),
                      const TextSpan(text: ' Meowville.'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.space4,
              left: AppSpacing.space4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.error_outline,
                  size: 15,
                  color: AppColors.onErrorContainer,
                ),
                const SizedBox(width: AppSpacing.space4),
                Expanded(
                  child: Text(
                    errorText!,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
