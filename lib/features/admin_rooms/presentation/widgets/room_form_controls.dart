import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class UnitStepper extends StatelessWidget {
  const UnitStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      value: '$value unit',
      increasedValue: value < max ? '${value + 1} unit' : null,
      decreasedValue: value > min ? '${value - 1} unit' : null,
      onIncrease: value < max ? () => onChanged(value + 1) : null,
      onDecrease: value > min ? () => onChanged(value - 1) : null,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.surfaceRecessed,
          borderRadius: AppRadius.controlAll,
          border: Border.all(color: AppColors.outlineStrong),
        ),
        child: Row(
          children: <Widget>[
            _StepButton(
              icon: Icons.remove_rounded,
              tooltip: 'Kurangi unit',
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
            Expanded(
              child: ExcludeSemantics(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineSm,
                ),
              ),
            ),
            _StepButton(
              icon: Icons.add_rounded,
              tooltip: 'Tambah unit',
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    return ExcludeSemantics(
      child: Material(
        color: enabled
            ? AppColors.surfaceContainerLowest
            : AppColors.surfaceRecessed,
        borderRadius: AppRadius.controlAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          hoverColor: AppColors.surfaceContainer,
          focusColor: AppColors.surfaceRecessedStrong,
          child: Tooltip(
            message: tooltip,
            child: SizedBox(
              width: AppSpacing.minTapTarget,
              height: AppSpacing.minTapTarget,
              child: Icon(
                icon,
                size: 20,
                color: enabled ? AppColors.onSurface : AppColors.outline,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OptionChipItem<T> {
  const OptionChipItem({required this.value, required this.label});

  final T value;
  final String label;
}

class OptionChips<T> extends StatelessWidget {
  const OptionChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<OptionChipItem<T>> options;
  final T? selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space8,
      runSpacing: AppSpacing.space8,
      children: <Widget>[
        for (final OptionChipItem<T> option in options)
          _OptionChip(
            label: option.label,
            selected: option.value == selected,
            onTap: () => onSelected(option.value),
          ),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: selected
              ? AppColors.surfaceContainerLowest
              : AppColors.surfaceRecessed,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.controlAll,
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.outlineStrong,
              width: selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            hoverColor: AppColors.surfaceContainer,
            focusColor: AppColors.surfaceRecessedStrong,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.minTapTarget,
                minWidth: 88,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space16,
                  vertical: AppSpacing.space12,
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelLg.copyWith(
                    color: selected
                        ? AppColors.brandTerracottaPressed
                        : AppColors.onSurfaceVariant,
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

class FieldErrorText extends StatelessWidget {
  const FieldErrorText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space4),
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              size: 15,
              color: AppColors.onErrorContainer,
            ),
            const SizedBox(width: AppSpacing.space4),
            Expanded(
              child: Text(
                text,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
