import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_elevation.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppDangerButton extends StatefulWidget {
  const AppDangerButton({
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
  State<AppDangerButton> createState() => _AppDangerButtonState();
}

class _AppDangerButtonState extends State<AppDangerButton> {
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null && !widget.isLoading;
    final Color background = !enabled
        ? AppColors.surfaceRecessed
        : (_pressed ? AppColors.errorPressed : AppColors.error);
    final Color foreground = enabled
        ? AppColors.onError
        : AppColors.onSurfacePlaceholder;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: AnimatedSlide(
            offset: _pressed ? const Offset(0, 0.042) : Offset.zero,
            duration: AppMotion.pressFast,
            child: Container(
              height: AppSpacing.controlHeight,
              decoration: BoxDecoration(
                color: background,
                borderRadius: AppRadius.controlAll,
                border: Border.all(
                  color: _focused ? AppColors.errorEdge : Colors.transparent,
                  width: 2,
                ),
                boxShadow: !enabled
                    ? const <BoxShadow>[]
                    : (_pressed
                          ? AppElevation.buttonDangerPressed
                          : AppElevation.buttonDangerRaised),
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
                  hoverColor: AppColors.errorPressed,
                  child: Center(
                    child: widget.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: foreground,
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
