import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/format.dart';
import '../../../widgets/app_photo.dart';
import '../../../widgets/common.dart';

class ReservationCard extends StatelessWidget {
  const ReservationCard({
    super.key,
    required this.reservation,
    this.onTap,
    this.showPrice = true,
  });

  final Reservation reservation;
  final VoidCallback? onTap;
  final bool showPrice;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final text = Theme.of(context).textTheme;
    final body = text.bodyMedium!.copyWith(fontSize: 15, height: 1.5);
    final dim =
        r.status == ReservationStatus.completed ||
        r.status == ReservationStatus.rejected ||
        r.status == ReservationStatus.cancelled;

    // Dengan font besar, badge pindah ke bawah nama supaya nama tidak
    // terpotong per huruf di kolom yang sempit.
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final badge = StatusBadge.booking(r.status.key);

    return AppCard(
      onTap: onTap,
      child: Column(
        spacing: AppSpacing.md,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: AppPhoto(r.cat.photo, size: 56, radius: 14),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.cat.name,
                      style: text.titleLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (largeText)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: badge,
                      ),
                    for (final line in [
                      r.cat.breedLabel,
                      'Owner: ${r.owner.name}',
                    ])
                      Text(
                        line,
                        style: text.bodySmall!.copyWith(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (!largeText)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: badge,
                ),
            ],
          ),
          Text.rich(
            TextSpan(
              style: body,
              children: [
                TextSpan(text: 'Kamar ${r.roomType.name} - '),
                if (r.unit == null && r.status == ReservationStatus.pending)
                  TextSpan(
                    text: 'Unit dipilih ketika diterima',
                    style: body.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.muted,
                    ),
                  )
                else if (r.unit != null)
                  TextSpan(text: r.unit),
                TextSpan(
                  text:
                      '\n${r.nights} malam dari ${Fmt.range(r.checkIn, r.checkOut)}',
                ),
              ],
            ),
          ),
          if (r.addons.isNotEmpty || showPrice)
            Row(
              spacing: AppSpacing.sm,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [for (final a in r.addons) TagChip(a.name)],
                  ),
                ),
                if (showPrice)
                  Text(
                    Fmt.rupiah(r.total),
                    style: text.labelLarge!.copyWith(
                      fontSize: 18,
                      color: dim ? AppColors.text : AppColors.primary,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
