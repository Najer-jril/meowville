import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/data.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';
import '../../routes/app_routes.dart';

class SitterTodayScreen extends StatelessWidget {
  const SitterTodayScreen({super.key, required this.actor});

  final AppUser actor;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AdminStore>();
    final text = Theme.of(context).textTheme;

    final checkIns = store.awaitingCheckIn;
    final staying = store.stayingNotLeaving;
    final checkOuts = store.dueCheckOut;
    final empty = checkIns.isEmpty && staying.isEmpty && checkOuts.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.xl,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          children: [
            Text('Hari Ini', style: text.headlineLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              Fmt.dateLong(store.today),
              style: text.bodySmall!.copyWith(fontSize: 15),
            ),
            if (empty)
              const EmptyState(
                icon: Icons.pets,
                title: 'Belum ada yang perlu ditangani',
                message:
                    'Kucing yang akan check-in, menginap, atau '
                    'check-out akan muncul di sini.',
              ),
            _Section(
              title: 'Mau check-in',
              items: checkIns,
              actor: actor,
              badge: (r) => r.checkIn.isBefore(store.today)
                  ? const StatusBadge(
                      label: 'Terlambat',
                      style: BadgeStyle(AppColors.danger, AppColors.dangerSoft),
                    )
                  : const StatusBadge(
                      label: 'Hari ini',
                      style: BadgeStyle(
                        AppColors.primary,
                        AppColors.primarySoft,
                      ),
                    ),
            ),
            _Section(
              title: 'Lagi Nginap',
              items: staying,
              actor: actor,
              badge: ReportBadge.new,
            ),
            _Section(
              title: 'Mau check-out',
              items: checkOuts,
              actor: actor,
              badge: ReportBadge.new,
            ),
          ],
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
    if (items.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text(
          '$title (${items.length})',
          style: text.titleLarge!.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final r in items) ...[
          GuestCard(
            reservation: r,
            badge: badge(r),
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.sitterBookingDetail,
              arguments: {'reservation': r, 'actor': actor},
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class ReportBadge extends StatelessWidget {
  const ReportBadge(this.reservation, {super.key});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final report = context.watch<AdminStore>().reportToday(reservation);
    if (report == null) {
      return const StatusBadge(
        label: 'Belum dilaporkan hari ini',
        style: BadgeStyle(AppColors.warning, AppColors.warningSoft),
      );
    }
    return StatusBadge(
      label:
          'Dilaporkan ${report.reporter.firstName}, ${Fmt.time(report.time)}',
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
          AppPhoto(r.cat.photo, size: 64),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
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
                const SizedBox(height: AppSpacing.sm),
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
