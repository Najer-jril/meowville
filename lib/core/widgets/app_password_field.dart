import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_text_field.dart';

class AppPasswordField extends StatelessWidget {
  const AppPasswordField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscured,
    required this.onToggleObscured,
    this.focusNode,
    this.icon,
    this.iconSide = AppTextFieldIconSide.leading,
    this.textInputAction = TextInputAction.done,
    this.autofillHints,
    this.enabled = true,
    this.errorText,
    this.semanticLabel,
    this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscured;
  final VoidCallback onToggleObscured;
  final FocusNode? focusNode;
  final IconData? icon;
  final AppTextFieldIconSide iconSide;
  final TextInputAction textInputAction;
  final List<String>? autofillHints;
  final bool enabled;
  final String? errorText;
  final String? semanticLabel;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final String toggleLabel = obscured
        ? 'Tampilkan kata sandi'
        : 'Sembunyikan kata sandi';

    return AppTextField(
      controller: controller,
      focusNode: focusNode,
      hintText: hintText,
      icon: icon,
      iconSide: iconSide,
      obscureText: obscured,
      enabled: enabled,
      errorText: errorText,
      semanticLabel: semanticLabel,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      suffix: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onToggleObscured : null,
          customBorder: const CircleBorder(),
          hoverColor: AppColors.surfaceContainer,
          focusColor: AppColors.surfaceContainer,
          child: Tooltip(
            message: toggleLabel,
            child: Semantics(
              button: true,
              label: toggleLabel,
              child: SizedBox(
                width: AppSpacing.minTapTarget,
                height: AppSpacing.minTapTarget,
                child: Icon(
                  obscured ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
