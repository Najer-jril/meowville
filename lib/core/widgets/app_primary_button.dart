import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_elevation.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppPrimaryButton extends StatefulWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.shadows = AppElevation.buttonRaised,
    this.foregroundColor = AppColors.onPrimary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final List<BoxShadow> shadows;
  final Color foregroundColor;

  @override
  State<AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<AppPrimaryButton> {
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null && !widget.isLoading;
    final Color background = !enabled
        ? AppColors.surfaceRecessed
        : (_pressed ? AppColors.primaryPressed : AppColors.primaryStrong);
    final Color foreground = enabled
        ? widget.foregroundColor
        : AppColors.onSurfacePlaceholder;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: ExcludeSemantics(
        child: Padding(
          // Ruang untuk tebal tombol agar tata letak tidak bergeser.
          padding: const EdgeInsets.only(bottom: 3),
          child: AnimatedSlide(
            offset: _pressed ? const Offset(0, 0.042) : Offset.zero,
            duration: const Duration(milliseconds: 90),
            child: Container(
              height: AppSpacing.controlHeight,
              decoration: BoxDecoration(
                color: background,
                borderRadius: AppRadius.controlAll,
                border: Border.all(
                  color: _focused
                      ? AppColors.brandTerracottaEdge
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: !enabled
                    ? const <BoxShadow>[]
                    : (_pressed ? AppElevation.buttonPressed : widget.shadows),
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  onHighlightChanged: (bool pressed) =>
                      setState(() => _pressed = pressed),
                  onFocusChange: (bool focused) =>
                      setState(() => _focused = focused),
                  hoverColor: AppColors.brandTerracottaPressed,
                  child: Center(
                    child: widget.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: widget.foregroundColor,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              if (widget.leadingIcon != null) ...<Widget>[
                                Icon(
                                  widget.leadingIcon,
                                  size: 18,
                                  color: foreground,
                                ),
                                const SizedBox(width: AppSpacing.space8),
                              ],
                              Flexible(
                                child: Text(
                                  widget.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelLg.copyWith(
                                    color: foreground,
                                  ),
                                ),
                              ),
                              if (widget.trailingIcon != null) ...<Widget>[
                                const SizedBox(width: AppSpacing.space8),
                                Icon(
                                  widget.trailingIcon,
                                  size: 18,
                                  color: foreground,
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
