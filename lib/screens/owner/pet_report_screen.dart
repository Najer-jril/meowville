import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/daily_report_controller.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';
import 'widgets/owner_widgets.dart';

class PetReportScreen extends StatelessWidget {
  const PetReportScreen({super.key, required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final daily = context.watch<DailyReportController>();
    final text = Theme.of(context).textTheme;
    final r = reservation;

    final reports = daily.forReservation(r);

    return Scaffold(
      appBar: const SubPageAppBar(title: 'Laporan Harian'),
      body: RefreshIndicator(
        onRefresh: () => daily.load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: AppCard(
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.md),
                      child: AppPhoto(r.cat.photo, size: 56, radius: 14),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.cat.name, style: text.titleLarge),
                            Text(
                              [
                                ?r.unit,
                                Fmt.range(r.checkIn, r.checkOut),
                              ].join(' - '),
                              style: text.bodySmall!.copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: ownerStatusBadge(r),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (reports.isEmpty)
              AppCard(
                child: EmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'Belum ada laporan',
                  message: r.status == ReservationStatus.checkedIn
                      ? 'Laporan harian dari pet sitter akan muncul di '
                            'sini selama kucing menginap.'
                      : 'Tidak ada laporan untuk masa inap ini.',
                ),
              )
            else ...[
              for (var i = 0; i < reports.length; i++)
                _TimelineItem(
                  report: reports[i],
                  last: i == reports.length - 1,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.report, required this.last});

  final DailyReport report;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final d = report;
    return IntrinsicHeight(
      child: Row(
        spacing: AppSpacing.sm,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints.tightFor(
              width: AppSizes.timelineCol,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(width: 1.5, color: AppColors.border),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      '${Fmt.dayMonth(d.time)} - '
                                      '${Fmt.time(d.time)}',
                                  style: text.labelLarge!.copyWith(
                                    fontSize: 15,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      '  dari ${d.reporter?.firstName ?? 'staff'}',
                                  style: text.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                        StatusBadge(
                          label: d.mood,
                          style: AppBadges.mood(d.mood),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        'Makan ${d.food.toLowerCase()} dan '
                        'Minum ${d.drink.toLowerCase()}',
                        style: text.bodyMedium!.copyWith(fontSize: 15),
                      ),
                    ),
                    if (d.note.isNotEmpty)
                      Text(
                        d.note,
                        style: text.bodyMedium!.copyWith(
                          fontSize: 15,
                          color: AppColors.muted,
                        ),
                      ),
                    if (d.photo != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: GestureDetector(
                          onTap: () => showPhotoViewer(
                            context,
                            d.photo!,
                            title: 'Foto ${d.reservation.cat.name}',
                          ),
                          child: AppPhoto(
                            d.photo,
                            size: AppSizes.artLg,
                            radius: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
