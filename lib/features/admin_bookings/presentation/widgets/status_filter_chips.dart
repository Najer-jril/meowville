import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../dashboard/domain/entities/booking_status.dart';
import '../../../dashboard/presentation/widgets/booking_status_badge.dart';

const List<BookingStatus> adminStatusFilterOrder = <BookingStatus>[
  BookingStatus.pending,
  BookingStatus.confirmed,
  BookingStatus.checkedIn,
  BookingStatus.checkedOut,
  BookingStatus.rejected,
  BookingStatus.cancelled,
];

class StatusFilterChips extends StatelessWidget {
  const StatusFilterChips({
    super.key,
    required this.selected,
    required this.pendingCount,
    required this.onSelected,
  });

  final BookingStatus? selected;
  final int pendingCount;
  final ValueChanged<BookingStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: <Widget>[
          _Chip(
            label: 'Semua',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final BookingStatus status
              in adminStatusFilterOrder) ...<Widget>[
            const SizedBox(width: AppSpacing.space8),
            _Chip(
              label: BookingStatusBadge.labelFor(status),
              count: status == BookingStatus.pending && pendingCount > 0
                  ? pendingCount
                  : null,
              selected: selected == status,
              onTap: () => onSelected(status),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final Color foreground = selected
        ? AppColors.brandTerracottaPressed
        : AppColors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: count == null ? label : '$label, $count reservasi',
      child: ExcludeSemantics(
        child: Material(
          color: selected
              ? AppColors.surfaceContainerLowest
              : AppColors.surfaceRecessed,
          // DESIGN.md: penyaring memakai radius kontrol, bukan pil.
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.controlAll,
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.outlineStrong,
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
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space16,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      label,
                      style: AppTypography.labelMd.copyWith(color: foreground),
                    ),
                    if (count != null) ...<Widget>[
                      const SizedBox(width: AppSpacing.space8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space8,
                          vertical: AppSpacing.space2,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.pendingSurface,
                          borderRadius: AppRadius.pillAll,
                        ),
                        child: Text(
                          '$count',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.pendingText,
                          ),
                        ),
                      ),
                    ],
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
