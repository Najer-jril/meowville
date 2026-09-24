import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.selected = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final bool selected;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final Color foreground = !enabled
        ? AppColors.onSurfacePlaceholder
        : (widget.selected
              ? AppColors.brandTerracottaDark
              : AppColors.onSurface);
    final Color background = widget.selected
        ? AppColors.primarySoft
        : (_pressed ? AppColors.surfaceRecessed : Colors.transparent);

    return Tooltip(
      message: widget.semanticLabel,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: widget.semanticLabel,
        selected: widget.selected,
        child: ExcludeSemantics(
          child: SizedBox(
            width: AppSpacing.minTapTarget,
            height: AppSpacing.minTapTarget,
            child: Container(
              decoration: BoxDecoration(
                color: background,
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
                  customBorder: RoundedRectangleBorder(
                    borderRadius: AppRadius.controlAll,
                  ),
                  child: Center(
                    child: Icon(widget.icon, size: 20, color: foreground),
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
