import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_elevation.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/pet_labels.dart';
import '../../../../core/utils/relative_date.dart';
import '../../../dashboard/presentation/widgets/booking_status_badge.dart';
import '../../../dashboard/presentation/widgets/dashboard_bits.dart';
import '../../domain/entities/admin_booking.dart';

String _two(int value) => value.toString().padLeft(2, '0');

String _createdLabel(DateTime value) =>
    'Dibuat ${formatShortDate(value)}, ${_two(value.hour)}.${_two(value.minute)}';

List<String> _splitIncluded(String text) => text
    .split(RegExp(r'[\n,;]'))
    .map((String item) => item.trim())
    .where((String item) => item.isNotEmpty)
    .toList(growable: false);

class BookingSummaryHeader extends StatelessWidget {
  const BookingSummaryHeader({super.key, required this.booking});

  final AdminBooking booking;

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
                label: 'Reservasi ${booking.petName}, kode ${booking.code}',
                child: ExcludeSemantics(
                  child: Text(
                    'Reservasi ${booking.petName}',
                    style: AppTypography.headlineLg,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            BookingStatusBadge(status: booking.status),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          '${booking.code}  ·  ${_createdLabel(booking.createdAt)}',
          style: AppTypography.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppRadius.cardAll,
        boxShadow: AppElevation.elevated,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            width: double.infinity,
            color: AppColors.surfaceContainer,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
              vertical: AppSpacing.space12,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: AppRadius.baseAll,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: AppColors.brandTerracottaDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.space8),
                Semantics(
                  header: true,
                  child: Text(title, style: AppTypography.headlineSm),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(value, style: AppTypography.labelLg),
        ],
      ),
    );
  }
}

class _FactGrid extends StatelessWidget {
  const _FactGrid({required this.facts});

  final List<_Fact> facts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool stacked = constraints.maxWidth < 280;
        final List<Widget> rows = <Widget>[];
        final int step = stacked ? 1 : 2;
        for (int i = 0; i < facts.length; i += step) {
          if (rows.isNotEmpty) {
            rows.add(const SizedBox(height: AppSpacing.space12));
          }
          if (stacked) {
            rows.add(facts[i]);
            continue;
          }
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: facts[i]),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: i + 1 < facts.length
                      ? facts[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}

class PetDetailCard extends StatelessWidget {
  const PetDetailCard({super.key, required this.booking});

  final AdminBooking booking;

  @override
  Widget build(BuildContext context) {
    final double? weight = booking.petWeightKg;
    final String? aggressiveness = booking.petAggressiveness;

    return _DetailCard(
      title: 'Data kucing',
      icon: Icons.pets_rounded,
      children: <Widget>[
        _FactGrid(
          facts: <_Fact>[
            _Fact(label: 'Nama', value: booking.petName),
            if (booking.petBreed.isNotEmpty)
              _Fact(label: 'Ras', value: booking.petBreed),
            if (weight != null)
              _Fact(label: 'Berat', value: formatWeightKg(weight)),
            if (aggressiveness != null)
              _Fact(
                label: 'Tingkat agresivitas',
                value: aggressivenessLabel(aggressiveness),
              ),
          ],
        ),
        if (booking.careInstructions != null) ...<Widget>[
          const SizedBox(height: AppSpacing.space16),
          CareNote(
            label: 'Instruksi perawatan',
            text: booking.careInstructions!,
          ),
        ],
      ],
    );
  }
}

class OwnerDetailCard extends StatelessWidget {
  const OwnerDetailCard({super.key, required this.booking});

  final AdminBooking booking;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      title: 'Pawrent',
      icon: Icons.badge_rounded,
      children: <Widget>[
        _Fact(label: 'Nama', value: booking.ownerName),
        if (booking.ownerEmail != null) ...<Widget>[
          const SizedBox(height: AppSpacing.space12),
          _Fact(label: 'Email', value: booking.ownerEmail!),
        ],
      ],
    );
  }
}

class StayDetailCard extends StatelessWidget {
  const StayDetailCard({super.key, required this.booking});

  final AdminBooking booking;

  @override
  Widget build(BuildContext context) {
    final List<String> included = booking.includedServices == null
        ? const <String>[]
        : _splitIncluded(booking.includedServices!);

    return _DetailCard(
      title: 'Kamar & durasi',
      icon: Icons.apartment_rounded,
      children: <Widget>[
        _FactGrid(
          facts: <_Fact>[
            _Fact(label: 'Tier kamar', value: booking.roomType),
            _Fact(label: 'Lama menginap', value: '${booking.nights} malam'),
            _Fact(label: 'Check-in', value: formatShortDate(booking.checkin)),
            _Fact(label: 'Check-out', value: formatShortDate(booking.checkout)),
          ],
        ),
        if (included.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.space16),
          Text(
            'Paket bawaan tier',
            style: AppTypography.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          for (final String item in included)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space4),
              child: FactLine(icon: Icons.check_rounded, text: item),
            ),
        ],
      ],
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: Text(label, style: AppTypography.bodyMd)),
          const SizedBox(width: AppSpacing.space12),
          Text(formatRupiah(amount), style: AppTypography.tabularNumeric),
        ],
      ),
    );
  }
}

class AddOnDetailCard extends StatelessWidget {
  const AddOnDetailCard({super.key, required this.booking});

  final AdminBooking booking;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      title: 'Add-on',
      icon: Icons.auto_awesome_rounded,
      children: <Widget>[
        if (booking.addOns.isEmpty)
          Text(
            'Reservasi ini tanpa layanan tambahan.',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          )
        else
          for (int i = 0; i < booking.addOns.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.space8),
            _MoneyRow(
              label: booking.addOns[i].name,
              amount: booking.addOns[i].priceAtBooking,
            ),
          ],
      ],
    );
  }
}

class CostDetailCard extends StatelessWidget {
  const CostDetailCard({super.key, required this.booking});

  final AdminBooking booking;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      title: 'Rincian biaya',
      icon: Icons.receipt_long_rounded,
      children: <Widget>[
        _MoneyRow(
          label: 'Sewa kamar ${booking.roomType}, ${booking.nights} malam',
          amount: booking.roomSubtotal,
        ),
        if (booking.addOns.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.space8),
          _MoneyRow(
            label: 'Add-on (${booking.addOns.length})',
            amount: booking.addOnTotal,
          ),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.space12),
          child: Divider(height: 1, color: AppColors.outlineVariant),
        ),
        MergeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(child: Text('Total', style: AppTypography.labelLg)),
              const SizedBox(width: AppSpacing.space12),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    formatRupiah(booking.totalPrice),
                    style: AppTypography.headlineMd.copyWith(
                      color: AppColors.brandTerracottaDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
