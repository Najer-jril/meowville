import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';

import '../../data/data.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'widgets/owner_widgets.dart';

class OwnerHomeScreen extends StatelessWidget {
  const OwnerHomeScreen({super.key, this.onSeeBookings});

  final VoidCallback? onSeeBookings;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AdminStore>();
    final text = Theme.of(context).textTheme;

    void push(String route, [Object? args]) =>
        Navigator.pushNamed(context, route, arguments: args);

    final owner = store.currentOwner;
    final mine = store.reservationsOf(owner);
    final staying = mine
        .where((r) => r.status == ReservationStatus.checkedIn)
        .toList();
    final upcoming =
        mine
            .where(
              (r) =>
                  r.status == ReservationStatus.pending ||
                  r.status == ReservationStatus.confirmed,
            )
            .toList()
          ..sort((a, b) => a.checkIn.compareTo(b.checkIn));
    final nearest = upcoming.isEmpty ? null : upcoming.first;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.xl,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                spacing: AppSpacing.xs,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Halo, ${owner.firstName}', style: text.headlineLarge),
                  Text(
                    Fmt.dateLong(store.today),
                    style: text.bodySmall!.copyWith(fontSize: 15),
                  ),
                ],
              ),
              if (staying.isEmpty && nearest == null)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xl),
                  child: AppCard(
                    child: EmptyState(
                      icon: Icons.pets,
                      title: 'Belum ada reservasi',
                      message: 'Pesan kamar untuk kucing kesayanganmu.',
                    ),
                  ),
                ),
              if (staying.isNotEmpty) ...[
                const _SectionTitle('Lagi Nginap'),
                for (final r in staying)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _StayingCard(
                      reservation: r,
                      onTap: () => push(AppRoutes.ownerBookingDetail, r),
                      onReport: () => push(AppRoutes.ownerPetReport, r),
                    ),
                  ),
              ],
              if (nearest != null) ...[
                _SectionTitle(
                  'Booking terdekat',
                  action: upcoming.length > 1 ? 'Lihat semua' : null,
                  onAction: onSeeBookings,
                ),
                OwnerBookingCard(
                  reservation: nearest,
                  onTap: () => push(AppRoutes.ownerBookingDetail, nearest),
                ),
                if (nearest.status == ReservationStatus.pending &&
                    nearest.paymentProof == null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: ProofDeadlineNotice(nearest),
                  ),
              ],
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.xl,
                  bottom: AppSpacing.xs,
                ),
                child: FilledButton.icon(
                  onPressed: () => push(AppRoutes.ownerReservationFlow),
                  label: const Text('Pesan Kamar'),
                ),
              ),
              OutlinedButton(
                onPressed: () => push(AppRoutes.ownerRoomCatalog),
                child: const Text('Lihat tipe kamar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: text.titleLarge!.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

class _StayingCard extends StatelessWidget {
  const _StayingCard({
    required this.reservation,
    required this.onTap,
    required this.onReport,
  });

  final Reservation reservation;
  final VoidCallback onTap;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AdminStore>();
    final text = Theme.of(context).textTheme;
    final report = store.reportToday(reservation);
    return Column(
      spacing: AppSpacing.sm,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OwnerBookingCard(reservation: reservation, onTap: onTap),
        Material(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.input),
          child: InkWell(
            onTap: onReport,
            borderRadius: BorderRadius.circular(AppRadius.input),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: AppSpacing.md),
                    child: Icon(
                      Icons.assignment_outlined,
                      color: AppColors.primaryDeep,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      report == null
                          ? 'Lihat laporan harian'
                          : 'Laporan hari ini: ${report.mood} - '
                                '${Fmt.time(report.time)}',
                      style: text.labelLarge!.copyWith(
                        fontSize: 15,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.primaryDeep),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
