import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/data.dart';
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
    final store = context.watch<AdminStore>();
    final text = Theme.of(context).textTheme;
    final r = reservation;

    final reports = store.reportHistory
        .where((d) => d.reservation == r)
        .toList();

    return Scaffold(
      appBar: const SubPageAppBar(title: 'Laporan Harian'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.xl,
        ),
        children: [
          AppCard(
            child: Row(
              children: [
                AppPhoto(r.cat.photo, size: 56, radius: 14),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.cat.name, style: text.titleLarge),
                      Text(
                        [?r.unit, Fmt.range(r.checkIn, r.checkOut)].join(' - '),
                        style: text.bodySmall!.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.lg),
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
              _TimelineItem(report: reports[i], last: i == reports.length - 1),
          ],
        ],
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 22),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(width: 1.5, color: AppColors.border),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
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
                                  text: '  dari ${d.reporter.firstName}',
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
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Makan ${d.food.toLowerCase()} dan '
                      'Minum ${d.drink.toLowerCase()}',
                      style: text.bodyMedium!.copyWith(fontSize: 15),
                    ),
                    if (d.note.isNotEmpty)
                      Text(
                        d.note,
                        style: text.bodyMedium!.copyWith(
                          fontSize: 15,
                          color: AppColors.muted,
                        ),
                      ),
                    if (d.photo != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      GestureDetector(
                        onTap: () => showPhotoViewer(
                          context,
                          d.photo!,
                          title: 'Foto ${d.reservation.cat.name}',
                        ),
                        child: AppPhoto(d.photo, size: 64, radius: 12),
                      ),
                    ],
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
