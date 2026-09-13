import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_elevation.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppSecondaryButton extends StatefulWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final bool isLoading;

  @override
  State<AppSecondaryButton> createState() => _AppSecondaryButtonState();
}

class _AppSecondaryButtonState extends State<AppSecondaryButton> {
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null && !widget.isLoading;
    final Color foreground = enabled
        ? AppColors.brandTerracottaDark
        : AppColors.onSurfacePlaceholder;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: ExcludeSemantics(
        child: Container(
          height: AppSpacing.controlHeight,
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.surfaceRecessed
                : AppColors.surfaceContainerLowest,
            borderRadius: AppRadius.controlAll,
            border: Border.all(
              color: _focused ? AppColors.primary : AppColors.outlineVariant,
              width: _focused ? 2 : 1,
            ),
            boxShadow: _pressed || !enabled
                ? const <BoxShadow>[]
                : AppElevation.buttonSecondary,
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
              hoverColor: AppColors.surfaceContainer,
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
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
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
