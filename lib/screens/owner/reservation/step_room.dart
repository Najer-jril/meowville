import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/data.dart';
import '../../../data/models.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/format.dart';
import '../../../widgets/app_photo.dart';
import '../../../widgets/common.dart';

class StepRoom extends StatelessWidget {
  const StepRoom({
    super.key,
    required this.range,
    required this.selected,
    required this.onSelected,
  });

  final DateTimeRange range;
  final RoomType? selected;
  final ValueChanged<RoomType> onSelected;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AdminStore>();
    final text = Theme.of(context).textTheme;
    final nights = range.duration.inDays;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        AppSpacing.xl,
      ),
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.muted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '${Fmt.range(range.start, range.end)} - $nights malam',
                style: text.bodyMedium!.copyWith(color: AppColors.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final t in store.activeRoomTypes) ...[
          _RoomOption(
            type: t,
            nights: nights,
            full: store.remainingFor(t, range.start, range.end) < 1,
            selected: t == selected,
            onTap: () => onSelected(t),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}

class _RoomOption extends StatelessWidget {
  const _RoomOption({
    required this.type,
    required this.nights,
    required this.full,
    required this.selected,
    required this.onTap,
  });

  final RoomType type;
  final int nights;
  final bool full;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final shown = type.packages.take(3).toList();

    final card = Material(
      color: selected ? AppColors.primarySoft : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: full ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPhoto(
                    type.photo,
                    size: 72,
                    placeholderIcon: Icons.bed_outlined,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.name,
                          style: text.titleLarge!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${Fmt.rupiah(type.price)} / malam',
                          style: text.bodyMedium!.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [for (final p in shown) TagChip(p)],
                        ),
                      ],
                    ),
                  ),
                  if (full)
                    const StatusBadge.inactive()
                  else
                    Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: selected ? AppColors.primary : AppColors.muted,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.surface.withValues(alpha: 0.7)
                      : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        full ? 'Penuh di tanggal ini' : 'Total ($nights malam)',
                        style: text.bodyMedium!.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    if (!full)
                      Text(
                        Fmt.rupiah(type.price * nights),
                        style: text.labelLarge!.copyWith(
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return full ? Opacity(opacity: 0.55, child: card) : card;
  }
}
