import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/relative_date.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_inline_link.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../domain/entities/admin_dashboard.dart';
import '../../domain/entities/booking_status.dart';
import '../../domain/entities/booking_summary.dart';
import '../../domain/entities/tier_occupancy.dart';
import '../widgets/booking_status_badge.dart';
import '../widgets/dashboard_bits.dart';
import '../widgets/dashboard_section.dart';
import '../widgets/dashboard_state_panels.dart';
import '../widgets/pet_avatar.dart';
import '../widgets/summary_stat_card.dart';
import '../widgets/tap_card.dart';

String adminGreetingSubtitle(AdminDashboard data) {
  final String date = formatShortDate(data.today);
  if (data.pendingCount == 0) {
    return '$date. Tidak ada reservasi yang menunggu keputusan.';
  }
  return '$date. ${data.pendingCount} reservasi menunggu keputusan.';
}

class PendingBookingsSection extends StatelessWidget {
  const PendingBookingsSection({
    super.key,
    required this.data,
    required this.now,
    required this.onOpenProof,
  });

  final AdminDashboard data;
  final DateTime now;
  final ValueChanged<BookingSummary> onOpenProof;

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      title: 'Perlu keputusan Anda',
      child: data.pending.isEmpty
          ? const DashboardEmptyPanel(
              icon: Icons.inbox_rounded,
              title: 'Tidak ada reservasi yang menunggu persetujuan.',
              message: 'Reservasi baru dari pemilik muncul di sini.',
              compact: true,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final BookingSummary booking in data.pending) ...<Widget>[
                  PendingBookingCard(
                    booking: booking,
                    now: now,
                    onOpenProof: () => onOpenProof(booking),
                  ),
                  const SizedBox(height: AppSpacing.space12),
                ],
              ],
            ),
    );
  }
}

class PendingBookingCard extends StatelessWidget {
  const PendingBookingCard({
    super.key,
    required this.booking,
    required this.now,
    required this.onOpenProof,
  });

  final BookingSummary booking;
  final DateTime now;
  final VoidCallback onOpenProof;

  @override
  Widget build(BuildContext context) {
    final String unit = booking.unitCode == null
        ? ''
        : ' - ${booking.unitCode}';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              PetAvatar(name: booking.pet.name, photoUrl: booking.pet.photoUrl),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(booking.pet.name, style: AppTypography.headlineSm),
                    Text(
                      booking.pet.breed,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      booking.code,
                      style: AppTypography.tabularNumeric.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),
          if (booking.ownerName != null) ...<Widget>[
            FactLine(
              icon: Icons.person_outline_rounded,
              text: 'Pemilik: ${booking.ownerName}',
            ),
            const SizedBox(height: AppSpacing.space8),
          ],
          FactLine(
            icon: Icons.bed_rounded,
            text: 'Kamar ${booking.roomType}$unit',
          ),
          const SizedBox(height: AppSpacing.space8),
          FactLine(
            icon: Icons.event_rounded,
            text: stayRange(booking.checkin, booking.checkout),
          ),
          if (booking.totalPrice != null) ...<Widget>[
            const SizedBox(height: AppSpacing.space8),
            FactLine(
              icon: Icons.payments_rounded,
              text: 'Total ${formatRupiah(booking.totalPrice!)}',
            ),
          ],
          const SizedBox(height: AppSpacing.space8),
          FactLine(
            icon: Icons.schedule_rounded,
            text:
                'Diajukan ${relativeTime(booking.createdAt, now: now).toLowerCase()}',
          ),
          if (booking.hasCareInstructions) ...<Widget>[
            const SizedBox(height: AppSpacing.space12),
            CareNote(text: booking.careInstructions!),
          ],
          const SizedBox(height: AppSpacing.space12),
          booking.hasPaymentProof
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: AppInlineLink(text: 'Lihat Bukti', onTap: onOpenProof),
                )
              : const FactLine(
                  icon: Icons.info_outline_rounded,
                  text: 'Bukti bayar belum diunggah',
                ),
        ],
      ),
    );
  }
}

class AdminSummaryGrid extends StatelessWidget {
  const AdminSummaryGrid({super.key, required this.data});

  final AdminDashboard data;

  @override
  Widget build(BuildContext context) {
    return SummaryGrid(
      cards: <Widget>[
        SummaryStatCard(
          label: 'Check-in Hari Ini',
          value: '${data.checkinTodayCount}',
          detail:
              '${data.arrivedTodayCount} sudah tiba, '
              '${data.waitingTodayCount} menunggu',
        ),
        SummaryStatCard(
          label: 'Check-out Hari Ini',
          value: '${data.checkoutTodayCount}',
        ),
        SummaryStatCard(
          label: 'Aktif Menginap',
          value: '${data.stayingCount}',
          detail: '${data.capacityPercent}% kapasitas',
        ),
        SummaryStatCard(
          label: 'Kamar Kosong',
          value: '${data.availableUnits}',
          detail: data.occupancy
              .map(
                (TierOccupancy t) => '${t.tier.roomType} ${t.availableUnits}',
              )
              .join(', '),
        ),
      ],
    );
  }
}

class OccupancySection extends StatelessWidget {
  const OccupancySection({super.key, required this.occupancy});

  final List<TierOccupancy> occupancy;

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      title: 'Okupansi kamar',
      child: occupancy.isEmpty
          ? const DashboardEmptyPanel(
              icon: Icons.bed_rounded,
              title: 'Belum ada tipe kamar.',
              message: 'Tambahkan tipe kamar dan unitnya di layar Kamar.',
              compact: true,
            )
          : AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int i = 0; i < occupancy.length; i++) ...<Widget>[
                    if (i > 0) ...<Widget>[
                      const Divider(
                        height: AppSpacing.space24,
                        color: AppColors.outlineVariant,
                      ),
                    ],
                    TierOccupancyBar(occupancy: occupancy[i]),
                  ],
                ],
              ),
            ),
    );
  }
}

class TierOccupancyBar extends StatelessWidget {
  const TierOccupancyBar({super.key, required this.occupancy});

  final TierOccupancy occupancy;

  @override
  Widget build(BuildContext context) {
    final TierOccupancy o = occupancy;
    final String footer = <String>[
      '${o.availableUnits} unit tersedia',
      if (o.blockedUnits > 0)
        '${o.blockedUnits} unit ditutup'
            '${o.blockedPurposes.isEmpty ? '' : ': ${o.blockedPurposes.join(', ')}'}',
    ].join(' - ');

    return Semantics(
      container: true,
      label:
          '${o.tier.roomType}: ${o.filledUnits} dari ${o.totalUnits} unit terisi, '
          '${o.percent} persen. $footer',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Expanded(
                child: Text(o.tier.roomType, style: AppTypography.labelLg),
              ),
              Text(
                '${o.filledUnits} / ${o.totalUnits}',
                style: AppTypography.tabularNumeric,
              ),
              const SizedBox(width: AppSpacing.space8),
              Text(
                '${o.percent}%',
                style: AppTypography.tabularNumeric.copyWith(
                  color: AppColors.brandTerracottaPressed,
                ),
              ),
            ],
          ),
          Text(
            '${formatRupiah(o.tier.pricePerNight)} / malam',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          UnitSegmentBar(total: o.totalUnits, filled: o.filledUnits),
          const SizedBox(height: AppSpacing.space8),
          Text(
            footer,
            style: AppTypography.caption.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class UnitSegmentBar extends StatelessWidget {
  const UnitSegmentBar({
    super.key,
    required this.total,
    required this.filled,
    this.blocked = 0,
    this.filledColor = AppColors.primaryStrong,
  });

  final int total;
  final int filled;
  final int blocked;

  final Color filledColor;

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return const SizedBox(height: 10);
    }
    return Row(
      children: <Widget>[
        for (int i = 0; i < total; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: i < filled
                    ? filledColor
                    : i < filled + blocked
                    ? AppColors.onSurfaceVariant
                    : AppColors.surfaceRecessedStrong,
                borderRadius: AppRadius.baseAll,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class MissingReportsSection extends StatelessWidget {
  const MissingReportsSection({
    super.key,
    required this.missing,
    required this.stayingCount,
    required this.onOpenSitters,
  });

  final List<BookingSummary> missing;
  final int stayingCount;
  final VoidCallback onOpenSitters;

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (stayingCount == 0) {
      body = const DashboardEmptyPanel(
        icon: Icons.article_rounded,
        title: 'Belum ada tamu yang menginap.',
        message: 'Laporan harian dihitung setelah ada tamu yang check-in.',
        compact: true,
      );
    } else if (missing.isEmpty) {
      body = const DashboardEmptyPanel(
        icon: Icons.task_alt_rounded,
        title: 'Semua laporan hari ini sudah masuk.',
        message: 'Setiap tamu menginap sudah punya catatan dari penjaga.',
        compact: true,
      );
    } else {
      body = AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '${missing.length} tamu belum ada laporan hari ini',
              style: AppTypography.labelLg,
            ),
            const SizedBox(height: AppSpacing.space12),
            for (final BookingSummary booking in missing) ...<Widget>[
              Row(
                children: <Widget>[
                  PetAvatar(
                    name: booking.pet.name,
                    photoUrl: booking.pet.photoUrl,
                    size: 36,
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(booking.pet.name, style: AppTypography.bodyMd),
                        if (booking.assignedSitterId == null) ...<Widget>[
                          const SizedBox(height: AppSpacing.space4),
                          const InfoChip(text: 'Belum ada penjaga'),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space8),
            ],
            const SizedBox(height: AppSpacing.space4),
            AppSecondaryButton(
              label: 'Buka Daftar Penjaga',
              onPressed: onOpenSitters,
            ),
          ],
        ),
      );
    }
    return DashboardSection(title: 'Laporan harian belum masuk', child: body);
  }
}

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({
    super.key,
    required this.pendingCount,
    required this.onOpenBookings,
    required this.onOpenRooms,
    required this.onOpenOwners,
    required this.onOpenReports,
  });

  final int pendingCount;
  final VoidCallback onOpenBookings;
  final VoidCallback onOpenRooms;
  final VoidCallback onOpenOwners;
  final VoidCallback onOpenReports;

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      title: 'Aksi cepat',
      child: SummaryGrid(
        cards: <Widget>[
          _QuickAction(
            icon: Icons.event_note_rounded,
            label: 'Reservasi',
            badge: pendingCount > 0 ? '$pendingCount' : null,
            onTap: onOpenBookings,
          ),
          _QuickAction(
            icon: Icons.bed_rounded,
            label: 'Kamar',
            onTap: onOpenRooms,
          ),
          _QuickAction(
            icon: Icons.people_outline_rounded,
            label: 'Pawrent',
            onTap: onOpenOwners,
          ),
          _QuickAction(
            icon: Icons.article_rounded,
            label: 'Laporan',
            onTap: onOpenReports,
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapCard(
      onTap: onTap,
      semanticLabel: badge == null ? label : '$label, $badge menunggu',
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: ExcludeSemantics(
        child: Row(
          children: <Widget>[
            Icon(icon, size: 22, color: AppColors.brandTerracottaPressed),
            const SizedBox(width: AppSpacing.space12),
            Expanded(child: Text(label, style: AppTypography.labelLg)),
            if (badge != null)
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
                  badge!,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.pendingText,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class RecentBookingsSection extends StatelessWidget {
  const RecentBookingsSection({
    super.key,
    required this.data,
    required this.onOpenAll,
  });

  final AdminDashboard data;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      title: 'Reservasi terbaru',
      linkLabel: data.recent.isEmpty ? null : 'Lihat Semua',
      onLinkTap: onOpenAll,
      child: data.recent.isEmpty
          ? const DashboardEmptyPanel(
              icon: Icons.event_note_rounded,
              title: 'Belum ada reservasi.',
              message: 'Reservasi yang masuk akan tercatat di sini.',
              compact: true,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final BookingSummary booking in data.recent) ...<Widget>[
                  _RecentTile(
                    booking: booking,
                    services: data.servicesFor(booking),
                  ),
                  const SizedBox(height: AppSpacing.space8),
                ],
              ],
            ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.booking, required this.services});

  final BookingSummary booking;
  final List<String> services;

  @override
  Widget build(BuildContext context) {
    final String unit = booking.unitCode == null
        ? ''
        : ' - ${booking.unitCode}';
    final bool needsSitter =
        booking.status == BookingStatus.checkedIn &&
        booking.assignedSitterId == null;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              PetAvatar(
                name: booking.pet.name,
                photoUrl: booking.pet.photoUrl,
                size: 40,
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(booking.pet.name, style: AppTypography.labelLg),
                    Text(
                      <String>[
                        if (booking.pet.breed.isNotEmpty) booking.pet.breed,
                        if (booking.ownerName != null) booking.ownerName!,
                      ].join(' - '),
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    BookingStatusBadge(status: booking.status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            'Kamar ${booking.roomType}$unit - '
            '${stayRange(booking.checkin, booking.checkout)}',
            style: AppTypography.bodySm,
          ),
          if (services.isNotEmpty || needsSitter) ...<Widget>[
            const SizedBox(height: AppSpacing.space8),
            Wrap(
              spacing: AppSpacing.space8,
              runSpacing: AppSpacing.space8,
              children: <Widget>[
                for (final String service in services) InfoChip(text: service),
                if (needsSitter) const InfoChip(text: 'Belum ada penjaga'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
