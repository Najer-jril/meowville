import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/daily_report_controller.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';
import '../../utils/clock.dart';

class ReportHistoryScreen extends StatelessWidget {
  const ReportHistoryScreen({super.key});

  String _dayLabel(DateTime day, DateTime today) {
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hari ini - ${Fmt.dayMonth(day)}';
    if (diff == 1) return 'Kemarin - ${Fmt.dayMonth(day)}';
    return Fmt.dateLong(day);
  }

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<DailyReportController>();
    final text = Theme.of(context).textTheme;

    final groups = <DateTime, List<DailyReport>>{};
    for (final d in reports.history) {
      final day = DateTime(d.time.year, d.time.month, d.time.day);
      groups.putIfAbsent(day, () => []).add(d);
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => reports.load(),
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
                    Text('Riwayat', style: text.headlineLarge),
                    Text(
                      'Laporan semua pet sitter',
                      style: text.bodySmall!.copyWith(fontSize: 15),
                    ),
                  ],
                ),
                if (reports.error != null && groups.isEmpty)
                  ErrorState(
                    message: reports.error!,
                    onRetry: () => reports.load(),
                  )
                else if (groups.isEmpty)
                  const EmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'Belum ada laporan',
                    message:
                        'Laporan harian yang dikirim pet sitter akan '
                        'muncul di sini.',
                  ),
                for (final e in groups.entries)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: Column(
                      spacing: AppSpacing.md,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _dayLabel(e.key, Clock.today()),
                          style: text.labelLarge,
                        ),
                        for (final d in e.value) _ReportCard(report: d),
                      ],
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

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final DailyReport report;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cat = report.reservation.cat;
    return AppCard(
      onTap: () => showReportDetailSheet(context, report),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: AppPhoto(cat.photo, size: 56, radius: 14),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.name, style: text.titleLarge),
                Text(
                  '${report.reporterFirstName} - ${Fmt.time(report.time)}',
                  style: text.bodySmall!.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
          StatusBadge(label: report.mood, style: AppBadges.mood(report.mood)),
        ],
      ),
    );
  }
}

Future<void> showReportDetailSheet(BuildContext context, DailyReport report) {
  final r = report.reservation;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final text = Theme.of(ctx).textTheme;
      Widget row(String label, Widget value) => Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: text.bodyLarge!.copyWith(color: AppColors.muted),
              ),
            ),
            value,
          ],
        ),
      );
      Widget strong(String v) => Text(v, style: text.labelLarge);

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: AppSpacing.md),
                      child: IconBubble(
                        icon: Icons.assignment_outlined,
                        size: 44,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Laporan ${r.cat.name}',
                        style: text.titleLarge!.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (r.unit != null) TagChip('Kamar ${r.unit}'),
                  ],
                ),
              ),
              row('Pelapor', strong(report.reporterFullName)),
              row(
                'Waktu',
                strong('${Fmt.date(report.time)}, ${Fmt.time(report.time)}'),
              ),
              row('Makan', strong(report.food)),
              row('Minum', strong(report.drink)),
              row(
                'Mood',
                StatusBadge(
                  label: report.mood,
                  style: AppBadges.mood(report.mood),
                ),
              ),
              if (report.note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Column(
                    spacing: AppSpacing.sm,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'CATATAN',
                        style: text.labelSmall!.copyWith(letterSpacing: 1.2),
                      ),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(AppRadius.input),
                        ),
                        child: Text(report.note, style: text.bodyLarge),
                      ),
                    ],
                  ),
                ),
              if (report.photo != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => showPhotoViewer(
                        ctx,
                        report.photo!,
                        title: 'Foto ${r.cat.name}',
                      ),
                      child: AppPhoto(report.photo, size: 120),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
