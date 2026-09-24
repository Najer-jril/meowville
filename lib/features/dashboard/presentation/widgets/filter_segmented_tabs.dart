import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class FilterTabOption {
  const FilterTabOption({required this.label, this.count});

  final String label;
  final int? count;

  String get text => count == null ? label : '$label ($count)';
}

class FilterSegmentedTabs extends StatelessWidget {
  const FilterSegmentedTabs({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<FilterTabOption> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: const BoxDecoration(
        color: AppColors.surfaceRecessed,
        borderRadius: AppRadius.controlAll,
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < options.length; i++)
            Expanded(
              child: _Segment(
                text: options[i].text,
                selected: i == selectedIndex,
                onTap: () => onSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: text,
      child: ExcludeSemantics(
        child: Material(
          color: selected
              ? AppColors.surfaceContainerLowest
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.control - 4),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.control - 4),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.minTapTarget,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space4,
                  ),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMd.copyWith(
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
      ),
    );
  }
}
