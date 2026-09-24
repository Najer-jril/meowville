import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/relative_date.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../dashboard/domain/entities/tier_occupancy.dart';
import '../../../dashboard/presentation/sections/admin_sections.dart';
import '../../../dashboard/presentation/widgets/dashboard_bits.dart';
import '../../../dashboard/presentation/widgets/tap_card.dart';
import '../../domain/entities/room_catalog.dart';
import '../../domain/entities/room_type.dart';

String blockRangeLabel(RoomBlock block) => block.dateStart == block.dateEnd
    ? formatShortDate(block.dateStart)
    : '${formatShortDate(block.dateStart)} - ${formatShortDate(block.dateEnd)}';

extension RoomTypeAccent on RoomType {
  Color get accent => switch (this) {
    RoomType.standard => AppColors.brandTerracottaLight,
    RoomType.deluxe => AppColors.brandTerracottaDark,
    RoomType.suite => AppColors.brandGreen,
  };
}

class RoomTierCard extends StatelessWidget {
  const RoomTierCard({super.key, required this.room, required this.onEdit});

  final AdminRoom room;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final TierOccupancy o = room.today;
    final Color accent = room.type.accent;
    final String price = '${formatRupiah(room.tier.pricePerNight)} / malam';
    final String availability =
        '${o.availableUnits} dari ${o.totalUnits} unit tersedia';
    final String usage = <String>[
      '${o.filledUnits} terisi',
      if (o.blockedUnits > 0)
        '${o.blockedUnits} ditutup'
            '${o.blockedPurposes.isEmpty ? '' : ' (${o.blockedPurposes.join(', ')})'}',
    ].join(', ');

    return TapCard(
      onTap: onEdit,
      padding: EdgeInsets.zero,
      semanticLabel:
          'Tipe ${room.tier.roomType}, $price. Hari ini $availability, '
          '$usage. Ubah tipe kamar.',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Flexible(
                                  child: Text(
                                    room.tier.roomType,
                                    style: AppTypography.headlineMd,
                                  ),
                                ),
                                if (o.blockedUnits > 0) ...<Widget>[
                                  const SizedBox(width: AppSpacing.space8),
                                  _BlockedBadge(count: o.blockedUnits),
                                ],
                              ],
                            ),
                            const SizedBox(height: AppSpacing.space2),
                            Text(
                              price,
                              style: AppTypography.labelLg.copyWith(
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space8),
                      Container(
                        width: AppSpacing.minTapTarget,
                        height: AppSpacing.minTapTarget,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceRecessed,
                          borderRadius: AppRadius.controlAll,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 20,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Tersedia hari ini',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        '${o.availableUnits} / ${o.totalUnits} unit',
                        style: AppTypography.tabularNumeric,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  UnitSegmentBar(
                    total: o.totalUnits,
                    filled: o.filledUnits,
                    blocked: o.blockedUnits,
                    filledColor: accent,
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          usage,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        'Total: ${o.totalUnits} unit',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (room.tier.includedServices != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(AppRadius.card),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Paket bawaan',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      room.tier.includedServices!,
                      style: AppTypography.bodySm.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class RoomBlockCard extends StatelessWidget {
  const RoomBlockCard({
    super.key,
    required this.block,
    required this.today,
    required this.deleting,
    required this.onDelete,
  });

  final RoomBlock block;
  final DateTime today;
  final bool deleting;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final String range = blockRangeLabel(block);
    final bool ongoing = block.coversDay(today);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: AppSpacing.space8,
                    runSpacing: AppSpacing.space8,
                    children: <Widget>[
                      InfoChip(text: block.roomType),
                      InfoChip(text: '${block.blockedUnits} unit'),
                      if (ongoing) const InfoChip(text: 'Berlangsung'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  Text(range, style: AppTypography.labelLg),
                  if (block.purpose != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      'Keperluan: ${block.purpose}',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
          SizedBox(
            width: AppSpacing.minTapTarget,
            height: AppSpacing.minTapTarget,
            child: deleting
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.space12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onErrorContainer,
                    ),
                  )
                : IconButton(
                    onPressed: onDelete,
                    tooltip: 'Hapus blokir ${block.roomType} $range',
                    icon: const Icon(Icons.delete_outline_rounded, size: 22),
                    color: AppColors.onErrorContainer,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.errorContainer,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.controlAll,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BlockedBadge extends StatelessWidget {
  const _BlockedBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space8,
        vertical: AppSpacing.space2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        '$count unit diblokir',
        style: AppTypography.labelMd.copyWith(
          color: AppColors.onErrorContainer,
        ),
      ),
    );
  }
}
