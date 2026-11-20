import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/daily_report_controller.dart';
import '../../controllers/reservation_controller.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';
import '../../routes/app_routes.dart';
import '../../utils/clock.dart';

class SitterTodayScreen extends StatelessWidget {
  const SitterTodayScreen({super.key, required this.actor});

  final AppUser actor;

  @override
  Widget build(BuildContext context) {
    final reservations = context.watch<ReservationController>();
    final text = Theme.of(context).textTheme;

    final checkIns = reservations.awaitingCheckIn;
    final staying = reservations.stayingNotLeaving;
    final checkOuts = reservations.dueCheckOut;
    final empty = checkIns.isEmpty && staying.isEmpty && checkOuts.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => Future.wait([
            reservations.load(),
            context.read<DailyReportController>().load(),
          ]),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                    Text('Hari Ini', style: text.headlineLarge),
                    Text(
                      Fmt.dateLong(Clock.today()),
                      style: text.bodySmall!.copyWith(fontSize: 15),
                    ),
                  ],
                ),
                if (reservations.loading && empty)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (reservations.error != null && empty)
                  ErrorState(
                    message: reservations.error!,
                    onRetry: () => reservations.load(),
                  )
                else if (empty)
                  const EmptyState(
                    icon: Icons.pets,
                    title: 'Belum ada yang perlu ditangani',
                    message:
                        'Kucing yang akan check-in, menginap, atau '
                        'check-out akan muncul di sini.',
                  ),
                if (checkIns.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: _Section(
                      title: 'Mau check-in',
                      items: checkIns,
                      actor: actor,
                      badge: (r) => r.checkIn.isBefore(Clock.today())
                          ? const StatusBadge(
                              label: 'Terlambat',
                              style: BadgeStyle(
                                AppColors.danger,
                                AppColors.dangerSoft,
                              ),
                            )
                          : const StatusBadge(
                              label: 'Hari ini',
                              style: BadgeStyle(
                                AppColors.primary,
                                AppColors.primarySoft,
                              ),
                            ),
                    ),
                  ),
                if (staying.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: _Section(
                      title: 'Lagi Nginap',
                      items: staying,
                      actor: actor,
                      badge: ReportBadge.new,
                    ),
                  ),
                if (checkOuts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: _Section(
                      title: 'Mau check-out',
                      items: checkOuts,
                      actor: actor,
                      badge: ReportBadge.new,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    required this.actor,
    required this.badge,
  });

  final String title;
  final List<Reservation> items;
  final AppUser actor;
  final Widget Function(Reservation) badge;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      spacing: AppSpacing.md,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$title (${items.length})',
          style: text.titleLarge!.copyWith(fontWeight: FontWeight.w700),
        ),
        for (final r in items)
          GuestCard(
            reservation: r,
            badge: badge(r),
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.sitterBookingDetail,
              arguments: {'reservation': r, 'actor': actor},
            ),
          ),
      ],
    );
  }
}

class ReportBadge extends StatelessWidget {
  const ReportBadge(this.reservation, {super.key});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final report = context.watch<DailyReportController>().reportToday(
      reservation,
    );
    if (report == null) {
      return const StatusBadge(
        label: 'Belum dilaporkan hari ini',
        style: BadgeStyle(AppColors.warning, AppColors.warningSoft),
      );
    }
    return StatusBadge(
      label:
          'Dilaporkan ${report.reporterFirstName}, ${Fmt.time(report.time)}',
      style: const BadgeStyle(AppColors.success, AppColors.successSoft),
    );
  }
}

class GuestCard extends StatelessWidget {
  const GuestCard({
    super.key,
    required this.reservation,
    required this.badge,
    required this.onTap,
  });

  final Reservation reservation;
  final Widget badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final text = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: AppPhoto(r.cat.photo, size: 64),
          ),
          Expanded(
            child: Column(
              spacing: AppSpacing.sm,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: r.cat.name,
                            style: text.titleLarge!.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${r.unit ?? '-'} - ${Fmt.range(r.checkIn, r.checkOut)}',
                      style: text.bodyMedium!.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
                FittedBox(fit: BoxFit.scaleDown, child: badge),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }
}
