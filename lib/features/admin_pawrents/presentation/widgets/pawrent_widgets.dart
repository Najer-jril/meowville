import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/pet_labels.dart';
import '../../../../core/utils/relative_date.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../dashboard/domain/entities/booking_status.dart';
import '../../../dashboard/presentation/widgets/booking_status_badge.dart';
import '../../../dashboard/presentation/widgets/dashboard_bits.dart';
import '../../../dashboard/presentation/widgets/tap_card.dart';
import '../../domain/entities/pawrent.dart';

String _countLine(int pets, int bookings) =>
    '$pets kucing  ·  $bookings reservasi';

class PawrentCard extends StatelessWidget {
  const PawrentCard({super.key, required this.pawrent, required this.onTap});

  final PawrentSummary pawrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String counts = _countLine(pawrent.petCount, pawrent.bookingCount);

    return TapCard(
      onTap: onTap,
      showChevron: true,
      semanticLabel:
          '${pawrent.name}${pawrent.isStaying ? ', kucingnya sedang menginap' : ''}. '
          '${pawrent.email.isEmpty ? '' : '${pawrent.email}. '}'
          '$counts. Buka detail.',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    pawrent.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headlineSm,
                  ),
                ),
                if (pawrent.isStaying) ...<Widget>[
                  const SizedBox(width: AppSpacing.space8),
                  const BookingStatusBadge(status: BookingStatus.checkedIn),
                ],
              ],
            ),
            if (pawrent.email.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.space2),
              Text(
                pawrent.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.space8),
            Text(counts, style: AppTypography.bodySm),
          ],
        ),
      ),
    );
  }
}

class PawrentHeader extends StatelessWidget {
  const PawrentHeader({super.key, required this.pawrent});

  final PawrentDetail pawrent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Semantics(
                header: true,
                child: Text(pawrent.name, style: AppTypography.headlineLg),
              ),
            ),
            if (pawrent.isStaying) ...<Widget>[
              const SizedBox(width: AppSpacing.space8),
              const BookingStatusBadge(status: BookingStatus.checkedIn),
            ],
          ],
        ),
        if (pawrent.email.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.space4),
          Text(
            pawrent.email,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.space8),
        FactLine(
          icon: Icons.event_rounded,
          text: 'Terdaftar sejak ${formatShortDate(pawrent.joinedAt)}',
        ),
      ],
    );
  }
}

class PawrentSectionTitle extends StatelessWidget {
  const PawrentSectionTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(text, style: AppTypography.headlineMd),
    );
  }
}

class PawrentPetTile extends StatelessWidget {
  const PawrentPetTile({super.key, required this.pet});

  final PawrentPet pet;

  @override
  Widget build(BuildContext context) {
    final double? weight = pet.weightKg;
    final String? aggressiveness = pet.aggressiveness;

    return MergeSemantics(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(text: pet.name, style: AppTypography.labelLg),
                  if (pet.breed.isNotEmpty)
                    TextSpan(
                      text: '  ${pet.breed}',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (weight != null || aggressiveness != null) ...<Widget>[
              const SizedBox(height: AppSpacing.space8),
              Wrap(
                spacing: AppSpacing.space8,
                runSpacing: AppSpacing.space8,
                children: <Widget>[
                  if (weight != null) InfoChip(text: formatWeightKg(weight)),
                  if (aggressiveness != null)
                    InfoChip(
                      text:
                          'Agresivitas '
                          '${aggressivenessLabel(aggressiveness).toLowerCase()}',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PawrentBookingCard extends StatelessWidget {
  const PawrentBookingCard({
    super.key,
    required this.booking,
    required this.onTap,
  });

  final PawrentBooking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String status = BookingStatusBadge.labelFor(booking.status);
    final String range = stayRange(booking.checkin, booking.checkout);
    final String total = formatRupiah(booking.totalPrice);

    return TapCard(
      onTap: onTap,
      showChevron: true,
      semanticLabel:
          '${booking.petName}, $status. $range'
          '${booking.roomType.isEmpty ? '' : ', kamar ${booking.roomType}'}. '
          'Total $total. Buka detail reservasi.',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.space8,
                    runSpacing: AppSpacing.space4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(booking.petName, style: AppTypography.labelLg),
                      if (booking.roomType.isNotEmpty)
                        InfoChip(text: booking.roomType),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.space8),
                BookingStatusBadge(status: booking.status),
              ],
            ),
            const SizedBox(height: AppSpacing.space12),
            Text(
              range,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(total, style: AppTypography.tabularNumeric),
          ],
        ),
      ),
    );
  }
}
