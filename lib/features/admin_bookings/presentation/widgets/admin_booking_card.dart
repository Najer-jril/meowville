import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/relative_date.dart';
import '../../../dashboard/presentation/widgets/booking_status_badge.dart';
import '../../../dashboard/presentation/widgets/dashboard_bits.dart';
import '../../../dashboard/presentation/widgets/tap_card.dart';
import '../../domain/entities/admin_booking.dart';

class AdminBookingCard extends StatelessWidget {
  const AdminBookingCard({
    super.key,
    required this.booking,
    required this.onTap,
  });

  final AdminBooking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String status = BookingStatusBadge.labelFor(booking.status);
    final String range = stayRange(booking.checkin, booking.checkout);
    final int addOnCount = booking.addOns.length;

    return TapCard(
      onTap: onTap,
      showChevron: true,
      semanticLabel:
          '${booking.petName}, $status. Pawrent ${booking.ownerName}. '
          '$range, kamar ${booking.roomType}. Buka detail.',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        TextSpan(
                          text: booking.petName,
                          style: AppTypography.headlineSm,
                        ),
                        if (booking.petBreed.isNotEmpty)
                          TextSpan(
                            text: '  ${booking.petBreed}',
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.space8),
                BookingStatusBadge(status: booking.status),
              ],
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              'Pawrent: ${booking.ownerName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: AppSpacing.space12),
            Wrap(
              spacing: AppSpacing.space8,
              runSpacing: AppSpacing.space8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  range,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (booking.roomType.isNotEmpty)
                  InfoChip(text: booking.roomType),
                if (addOnCount > 0) InfoChip(text: '+$addOnCount add-on'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
