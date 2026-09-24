import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppGhostButton extends StatefulWidget {
  const AppGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;

  @override
  State<AppGhostButton> createState() => _AppGhostButtonState();
}

class _AppGhostButtonState extends State<AppGhostButton> {
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final Color foreground = enabled
        ? AppColors.brandTerracottaDark
        : AppColors.onSurfacePlaceholder;
    final Color background = _pressed
        ? AppColors.surfaceRecessed
        : AppColors.surfaceContainer;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: ExcludeSemantics(
        child: Container(
          height: AppSpacing.controlHeight,
          decoration: BoxDecoration(
            color: (_pressed || _focused) ? background : Colors.transparent,
            borderRadius: AppRadius.controlAll,
            border: Border.all(
              color: _focused ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (widget.leadingIcon != null) ...<Widget>[
                      Icon(widget.leadingIcon, size: 18, color: foreground),
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
