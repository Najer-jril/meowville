import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppTextFieldIconSide { leading, trailing }

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.focusNode,
    this.icon,
    this.iconSide = AppTextFieldIconSide.leading,
    this.suffix,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofillHints,
    this.obscureText = false,
    this.enabled = true,
    this.errorText,
    this.semanticLabel,
    this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final FocusNode? focusNode;
  final IconData? icon;
  final AppTextFieldIconSide iconSide;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final List<String>? autofillHints;
  final bool obscureText;
  final bool enabled;
  final String? errorText;
  final String? semanticLabel;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  FocusNode? _internalFocusNode;
  bool _hasFocus = false;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _internalFocusNode?.removeListener(_handleFocusChange);
      _focusNode.addListener(_handleFocusChange);
    }
  }

  void _handleFocusChange() {
    if (!mounted) {
      return;
    }
    final bool hasFocus = _focusNode.hasFocus;
    if (hasFocus != _hasFocus) {
      setState(() => _hasFocus = hasFocus);
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_handleFocusChange);
    _internalFocusNode?.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.errorText != null;

    final Color ringColor = hasError
        ? AppColors.error
        : (_hasFocus ? AppColors.primary : Colors.transparent);

    final Color fillColor = widget.enabled
        ? AppColors.surfaceRecessed
        : AppColors.surfaceRecessedStrong;

    final bool hasLeadingIcon =
        widget.icon != null && widget.iconSide == AppTextFieldIconSide.leading;
    final bool hasTrailingSlot =
        widget.suffix != null ||
        (widget.icon != null &&
            widget.iconSide == AppTextFieldIconSide.trailing);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          height: AppSpacing.controlHeight,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: AppRadius.controlAll,
            border: Border.all(color: ringColor, width: _hasFocus ? 2 : 1),
            boxShadow: _hasFocus
                ? const <BoxShadow>[
                    BoxShadow(
                      color: AppColors.focusGlow,
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Row(
            children: <Widget>[
              if (hasLeadingIcon)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.space12),
                  child: ExcludeSemantics(
                    child: Icon(
                      widget.icon,
                      size: 20,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: hasLeadingIcon
                        ? AppSpacing.space8
                        : AppSpacing.space12,
                    right: hasTrailingSlot ? 0 : AppSpacing.space12,
                  ),
                  child: Semantics(
                    textField: true,
                    label: widget.semanticLabel,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      obscureText: widget.obscureText,
                      keyboardType: widget.keyboardType,
                      textInputAction: widget.textInputAction,
                      textCapitalization: widget.textCapitalization,
                      inputFormatters: widget.inputFormatters,
                      autofillHints: widget.autofillHints,
                      onSubmitted: widget.onSubmitted,
                      onChanged: widget.onChanged,
                      cursorColor: AppColors.primary,
                      style: AppTypography.bodyMd,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        hintText: widget.hintText,
                        hintStyle: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfacePlaceholder,
                        ),
                        labelText: null,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.suffix != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.space4),
                  child: widget.suffix,
                )
              else if (widget.icon != null &&
                  widget.iconSide == AppTextFieldIconSide.trailing)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.space12),
                  child: ExcludeSemantics(
                    child: Icon(
                      widget.icon,
                      size: 20,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space4),
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
                    widget.errorText!,
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
