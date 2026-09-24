import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/relative_date.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_inline_link.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../domain/entities/booking_summary.dart';
import '../../domain/entities/daily_log_entry.dart';
import '../../domain/entities/owner_dashboard.dart';
import '../../domain/entities/pet_summary.dart';
import '../../domain/entities/room_tier.dart';
import '../widgets/booking_status_badge.dart';
import '../widgets/dashboard_bits.dart';
import '../widgets/dashboard_section.dart';
import '../widgets/dashboard_state_panels.dart';
import '../widgets/pet_avatar.dart';
import '../widgets/stay_progress_line.dart';
import '../widgets/tap_card.dart';

String ownerGreetingSubtitle(OwnerDashboard data, DateTime today) {
  switch (data.stayState) {
    case OwnerStayState.active:
      return '${data.active!.pet.name} sedang menginap di Meowville.';
    case OwnerStayState.upcoming:
      final BookingSummary next = data.nextUpcoming!;
      return '${next.pet.name} check-in '
          '${relativeDate(next.checkin, today: today).toLowerCase()}.';
    case OwnerStayState.none:
      return 'Belum ada reservasi. Pilih tanggal menginap untuk kucing Anda.';
  }
}

String _stayLine(BookingSummary booking) {
  final String unit = booking.unitCode == null ? '' : ' - ${booking.unitCode}';
  return 'Kamar ${booking.roomType}$unit';
}

String _petLine(PetSummary pet) {
  final List<String> parts = <String>[
    if (pet.breed.isNotEmpty) pet.breed,
    if (pet.sex != null) pet.sex!,
  ];
  return parts.join(' - ');
}

class ActiveStayHero extends StatelessWidget {
  const ActiveStayHero({
    super.key,
    required this.booking,
    required this.today,
    required this.onOpenReports,
    required this.onOpenBooking,
  });

  final BookingSummary booking;
  final DateTime today;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenBooking;

  @override
  Widget build(BuildContext context) {
    return AppCard.hero(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const ColoredBox(
            color: AppColors.primaryStrong,
            child: SizedBox(height: 4),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    PetAvatar(
                      name: booking.pet.name,
                      photoUrl: booking.pet.photoUrl,
                      size: 56,
                    ),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            booking.pet.name,
                            style: AppTypography.headlineMd,
                          ),
                          Text(
                            _petLine(booking.pet),
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: BookingStatusBadge(status: booking.status),
                ),
                const SizedBox(height: AppSpacing.space12),
                FactLine(icon: Icons.bed_rounded, text: _stayLine(booking)),
                const SizedBox(height: AppSpacing.space8),
                FactLine(
                  icon: Icons.event_rounded,
                  text: stayRange(booking.checkin, booking.checkout),
                ),
                const SizedBox(height: AppSpacing.space8),
                StayProgressLine(booking: booking, today: today),
                const SizedBox(height: AppSpacing.space20),
                _ButtonPair(
                  primaryLabel: 'Laporan Harian',
                  onPrimary: onOpenReports,
                  secondaryLabel: 'Detail Reservasi',
                  onSecondary: onOpenBooking,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonPair extends StatelessWidget {
  const _ButtonPair({
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget primary = AppPrimaryButton(
          label: primaryLabel,
          onPressed: onPrimary,
        );
        final Widget secondary = AppSecondaryButton(
          label: secondaryLabel,
          onPressed: onSecondary,
        );
        if (constraints.maxWidth < 320) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              primary,
              const SizedBox(height: AppSpacing.space8),
              secondary,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: primary),
            const SizedBox(width: AppSpacing.space12),
            Expanded(child: secondary),
          ],
        );
      },
    );
  }
}

class UpcomingStayCard extends StatelessWidget {
  const UpcomingStayCard({
    super.key,
    required this.booking,
    required this.today,
    required this.onTap,
  });

  final BookingSummary booking;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapCard(
      onTap: onTap,
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
                      'Check-in ${relativeDate(booking.checkin, today: today).toLowerCase()}',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.brandTerracottaPressed,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              BookingStatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),
          FactLine(icon: Icons.bed_rounded, text: _stayLine(booking)),
          const SizedBox(height: AppSpacing.space8),
          FactLine(
            icon: Icons.event_rounded,
            text: stayRange(booking.checkin, booking.checkout),
          ),
          if (booking.hasCareInstructions) ...<Widget>[
            const SizedBox(height: AppSpacing.space12),
            CareNote(text: booking.careInstructions!, label: 'Pesan Anda'),
          ],
        ],
      ),
    );
  }
}

class NewBookingBanner extends StatelessWidget {
  const NewBookingBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.badgeStayingSurface,
      borderColor: null,
      shadows: const <BoxShadow>[],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Reservasi baru',
            style: AppTypography.headlineSm.copyWith(
              color: AppColors.brandTerracottaPressed,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            'Pilih tanggal dan tipe kamar untuk kunjungan berikutnya.',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.brandTerracottaPressed,
            ),
          ),
          const SizedBox(height: AppSpacing.space12),
          AppPrimaryButton(label: 'Buat Reservasi Baru', onPressed: onTap),
        ],
      ),
    );
  }
}

class TodayReportsSection extends StatelessWidget {
  const TodayReportsSection({
    super.key,
    required this.logs,
    required this.now,
    required this.onOpenAll,
  });

  final List<DailyLogEntry> logs;
  final DateTime now;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      title: 'Kabar hari ini',
      child: logs.isEmpty
          ? const DashboardEmptyPanel(
              icon: Icons.article_rounded,
              title: 'Penjaga belum menulis kabar hari ini.',
              message: 'Laporan muncul di sini begitu penjaga mencatatnya.',
              compact: true,
            )
          : _LatestReport(logs: logs, now: now, onOpenAll: onOpenAll),
    );
  }
}

class _LatestReport extends StatelessWidget {
  const _LatestReport({
    required this.logs,
    required this.now,
    required this.onOpenAll,
  });

  final List<DailyLogEntry> logs;
  final DateTime now;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    final DailyLogEntry log = logs.first;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: AppSpacing.space8,
            runSpacing: AppSpacing.space8,
            children: <Widget>[
              if (log.mood != null) InfoChip(text: log.mood!),
              if (log.eatingTime != null)
                InfoChip(
                  text: 'Makan ${log.eatingTime}',
                  icon: Icons.restaurant_rounded,
                ),
            ],
          ),
          if (log.hasNote) ...<Widget>[
            const SizedBox(height: AppSpacing.space12),
            Text(
              '"${log.note}"',
              style: AppTypography.bodyMd.copyWith(height: 1.5),
            ),
          ],
          if (log.photoUrl != null) ...<Widget>[
            const SizedBox(height: AppSpacing.space12),
            ClipRRect(
              borderRadius: AppRadius.controlAll,
              child: Image.network(
                log.photoUrl!,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (
                  BuildContext context,
                  Object error,
                  StackTrace? trace,
                ) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space12),
          Row(
            children: <Widget>[
              if (log.authorName != null) ...<Widget>[
                PetAvatar(name: log.authorName!, size: 28),
                const SizedBox(width: AppSpacing.space8),
              ],
              Expanded(
                child: Text(
                  <String>[
                    if (log.authorName != null) log.authorName!,
                    relativeTime(log.createdAt, now: now),
                  ].join(' - '),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          Align(
            alignment: Alignment.centerLeft,
            child: AppInlineLink(
              text: 'Buka semua laporan (${logs.length} hari ini)',
              onTap: onOpenAll,
            ),
          ),
        ],
      ),
    );
  }
}

class PetsSection extends StatelessWidget {
  const PetsSection({
    super.key,
    required this.pets,
    required this.stayingPetIds,
    required this.onOpenPets,
  });

  final List<PetSummary> pets;
  final Set<String> stayingPetIds;
  final VoidCallback onOpenPets;

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      title: 'Anabul tersayang',
      child: pets.isEmpty
          ? DashboardEmptyPanel(
              icon: Icons.pets_rounded,
              title: 'Belum ada kucing terdaftar.',
              message: 'Tambahkan kucing Anda supaya bisa dititipkan.',
              actionLabel: 'Tambah Kucing',
              onAction: onOpenPets,
              compact: true,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final PetSummary pet in pets) ...<Widget>[
                  _PetTile(
                    pet: pet,
                    staying: stayingPetIds.contains(pet.id),
                    onTap: onOpenPets,
                  ),
                  const SizedBox(height: AppSpacing.space8),
                ],
                const SizedBox(height: AppSpacing.space4),
                AppSecondaryButton(
                  label: 'Tambah Kucing',
                  leadingIcon: Icons.add,
                  onPressed: onOpenPets,
                ),
              ],
            ),
    );
  }
}

class _PetTile extends StatelessWidget {
  const _PetTile({
    required this.pet,
    required this.staying,
    required this.onTap,
  });

  final PetSummary pet;
  final bool staying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String weight = pet.weightKg == null
        ? ''
        : '${pet.weightKg!.toStringAsFixed(pet.weightKg! % 1 == 0 ? 0 : 1)} kg';
    final String details = <String>[
      if (_petLine(pet).isNotEmpty) _petLine(pet),
      if (weight.isNotEmpty) weight,
    ].join(' - ');

    return TapCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.space12),
      child: Row(
        children: <Widget>[
          PetAvatar(name: pet.name, photoUrl: pet.photoUrl),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(pet.name, style: AppTypography.labelLg),
                if (details.isNotEmpty)
                  Text(
                    details,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                if (staying) ...<Widget>[
                  const SizedBox(height: AppSpacing.space8),
                  const _StayingBadge(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StayingBadge extends StatelessWidget {
  const _StayingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space8,
        vertical: AppSpacing.space4,
      ),
      decoration: const BoxDecoration(
        color: AppColors.badgeStayingSurface,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        'Sedang Menginap',
        style: AppTypography.labelMd.copyWith(
          color: AppColors.badgeStayingText,
        ),
      ),
    );
  }
}

class BookingHistorySection extends StatelessWidget {
  const BookingHistorySection({
    super.key,
    required this.history,
    required this.onOpenAll,
  });

  final List<BookingSummary> history;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      title: 'Riwayat reservasi',
      linkLabel: history.isEmpty ? null : 'Lihat Semua',
      onLinkTap: onOpenAll,
      child: history.isEmpty
          ? const DashboardEmptyPanel(
              icon: Icons.history_rounded,
              title: 'Belum ada riwayat reservasi.',
              message: 'Kunjungan yang sudah selesai akan tercatat di sini.',
              compact: true,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final BookingSummary booking in history) ...<Widget>[
                  TapCard(
                    onTap: onOpenAll,
                    padding: const EdgeInsets.all(AppSpacing.space12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                booking.pet.name,
                                style: AppTypography.labelLg,
                              ),
                            ),
                            BookingStatusBadge(status: booking.status),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.space4),
                        Text(
                          '${booking.roomType} - '
                          '${stayRange(booking.checkin, booking.checkout)}',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space8),
                ],
              ],
            ),
    );
  }
}

class RoomTiersSection extends StatelessWidget {
  const RoomTiersSection({
    super.key,
    required this.rooms,
    required this.onOpenRooms,
  });

  final List<RoomTier> rooms;
  final VoidCallback onOpenRooms;

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      title: 'Tipe kamar',
      child: rooms.isEmpty
          ? const DashboardEmptyPanel(
              icon: Icons.bed_rounded,
              title: 'Tipe kamar belum tersedia.',
              message: 'Daftar kamar muncul setelah admin menambahkannya.',
              compact: true,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final RoomTier room in rooms) ...<Widget>[
                  TapCard(
                    onTap: onOpenRooms,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.space8,
                          children: <Widget>[
                            Text(
                              room.roomType,
                              style: AppTypography.headlineSm,
                            ),
                            Text(
                              '${formatRupiah(room.pricePerNight)} / malam',
                              style: AppTypography.tabularNumeric.copyWith(
                                color: AppColors.brandTerracottaPressed,
                              ),
                            ),
                          ],
                        ),
                        if (room.description != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.space4),
                          Text(
                            room.description!,
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (room.includedServiceList.isNotEmpty) ...<Widget>[
                          const SizedBox(height: AppSpacing.space12),
                          Wrap(
                            spacing: AppSpacing.space8,
                            runSpacing: AppSpacing.space8,
                            children: <Widget>[
                              for (final String service
                                  in room.includedServiceList)
                                InfoChip(text: service),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space12),
                ],
              ],
            ),
    );
  }
}
