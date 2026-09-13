import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class AppCheckbox extends StatefulWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.size = 20,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String semanticLabel;
  final double size;
  final bool enabled;

  @override
  State<AppCheckbox> createState() => _AppCheckboxState();
}

class _AppCheckboxState extends State<AppCheckbox> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: widget.value,
      label: widget.semanticLabel,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.enabled ? () => widget.onChanged(!widget.value) : null,
          onFocusChange: (bool focused) => setState(() => _focused = focused),
          customBorder: const CircleBorder(),
          hoverColor: AppColors.surfaceContainer,
          focusColor: AppColors.surfaceContainer,
          child: ExcludeSemantics(
            child: SizedBox(
              width: AppSpacing.minTapTarget,
              height: AppSpacing.minTapTarget,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.value
                        ? AppColors.primary
                        : AppColors.surfaceRecessed,
                    borderRadius: AppRadius.baseAll,
                    border: Border.all(
                      color: _focused
                          ? AppColors.primary
                          : AppColors.outlineStrong,
                      width: _focused ? 2 : 1,
                    ),
                  ),
                  child: widget.value
                      ? Icon(
                          Icons.check,
                          size: widget.size - 4,
                          color: AppColors.onPrimary,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
