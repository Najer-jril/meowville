import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/relative_date.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../domain/entities/booking_summary.dart';
import '../../domain/entities/sitter_dashboard.dart';
import '../widgets/dashboard_bits.dart';
import '../widgets/dashboard_section.dart';
import '../widgets/dashboard_state_panels.dart';
import '../widgets/filter_segmented_tabs.dart';
import '../widgets/pet_avatar.dart';
import '../widgets/stay_progress_line.dart';
import '../widgets/summary_stat_card.dart';

String sitterGreetingSubtitle(SitterDashboard data) {
  final int count = data.stayingCount + data.waitingTodayCount;
  if (count == 0) {
    return 'Belum ada kucing yang ditugaskan untuk hari ini.';
  }
  return '$count anabul jadi tanggung jawab Anda hari ini.';
}

class SitterSummaryGrid extends StatelessWidget {
  const SitterSummaryGrid({super.key, required this.data});

  final SitterDashboard data;

  @override
  Widget build(BuildContext context) {
    return SummaryGrid(
      cards: <Widget>[
        SummaryStatCard(label: 'Tamu Menginap', value: '${data.stayingCount}'),
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
          label: 'Laporan Tertunda',
          value: '${data.pendingReportCount}',
          emphasis: data.pendingReportCount > 0,
        ),
      ],
    );
  }
}

class RecordReportCard extends StatelessWidget {
  const RecordReportCard({
    super.key,
    required this.pending,
    required this.onRecord,
    required this.onRecordFor,
  });

  final List<BookingSummary> pending;
  final VoidCallback onRecord;
  final ValueChanged<BookingSummary> onRecordFor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Catat laporan hari ini', style: AppTypography.headlineSm),
          const SizedBox(height: AppSpacing.space4),
          Text(
            pending.isEmpty
                ? 'Semua tamu menginap sudah punya laporan hari ini.'
                : 'Kucing di bawah ini belum dicatat. Ketuk namanya untuk '
                      'langsung menulis.',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (pending.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.space12),
            Wrap(
              spacing: AppSpacing.space8,
              runSpacing: AppSpacing.space8,
              children: <Widget>[
                for (final BookingSummary booking in pending)
                  _NameChip(
                    name: booking.pet.name,
                    onTap: () => onRecordFor(booking),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.space16),
          AppPrimaryButton(label: 'Mulai Catat Laporan', onPressed: onRecord),
        ],
      ),
    );
  }
}

class _NameChip extends StatelessWidget {
  const _NameChip({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Catat laporan untuk $name',
      child: ExcludeSemantics(
        child: Material(
          color: AppColors.badgeStayingSurface,
          borderRadius: AppRadius.pillAll,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.pillAll,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.minTapTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space16,
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    name,
                    style: AppTypography.labelLg.copyWith(
                      color: AppColors.badgeStayingText,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SitterTasksSection extends StatelessWidget {
  const SitterTasksSection({
    super.key,
    required this.data,
    required this.onRecordFor,
  });

  final SitterDashboard data;
  final ValueChanged<BookingSummary> onRecordFor;

  @override
  Widget build(BuildContext context) {
    final List<SitterTask> tasks = data.tasks;

    return DashboardSection(
      title: 'Prioritas tugas',
      child: tasks.isEmpty
          ? DashboardEmptyPanel(
              icon: Icons.task_alt_rounded,
              title: data.guests.isEmpty
                  ? 'Belum ada tamu yang ditugaskan kepada Anda.'
                  : 'Tidak ada tugas tertunda.',
              message: data.guests.isEmpty
                  ? 'Tugas muncul di sini setelah admin menugaskan kucing '
                        'kepada Anda.'
                  : 'Semua laporan hari ini sudah masuk.',
              compact: true,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final SitterTask task in tasks) ...<Widget>[
                  SitterTaskCard(
                    task: task,
                    onRecord: task.kind == SitterTaskKind.report
                        ? () => onRecordFor(task.booking)
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.space8),
                ],
              ],
            ),
    );
  }
}

class SitterTaskCard extends StatelessWidget {
  const SitterTaskCard({super.key, required this.task, this.onRecord});

  final SitterTask task;

  final VoidCallback? onRecord;

  static String titleFor(SitterTaskKind kind) => switch (kind) {
    SitterTaskKind.checkIn => 'Siap check-in',
    SitterTaskKind.checkOut => 'Check-out hari ini',
    SitterTaskKind.report => 'Laporan belum ditulis',
  };

  @override
  Widget build(BuildContext context) {
    final BookingSummary booking = task.booking;
    final String unit = booking.unitCode == null
        ? ''
        : ' - ${booking.unitCode}';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            titleFor(task.kind),
            style: AppTypography.labelMd.copyWith(
              color: AppColors.brandTerracottaPressed,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Row(
            children: <Widget>[
              PetAvatar(
                name: booking.pet.name,
                photoUrl: booking.pet.photoUrl,
                size: 44,
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(booking.pet.name, style: AppTypography.labelLg),
                    Text(
                      'Kamar ${booking.roomType}$unit',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onRecord != null) ...<Widget>[
            const SizedBox(height: AppSpacing.space12),
            AppPrimaryButton(label: 'Catat Laporan', onPressed: onRecord),
          ],
        ],
      ),
    );
  }
}

class StayingGuestsSection extends StatefulWidget {
  const StayingGuestsSection({
    super.key,
    required this.data,
    required this.onRecordFor,
    required this.onOpenLog,
  });

  final SitterDashboard data;
  final ValueChanged<BookingSummary> onRecordFor;
  final ValueChanged<BookingSummary> onOpenLog;

  @override
  State<StayingGuestsSection> createState() => _StayingGuestsSectionState();
}

class _StayingGuestsSectionState extends State<StayingGuestsSection> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final SitterDashboard data = widget.data;
    final List<List<BookingSummary>> byFilter = <List<BookingSummary>>[
      data.stayingGuests,
      data.pendingReportGuests,
      data.completedReportGuests,
    ];
    final List<BookingSummary> shown = byFilter[_filter];

    return DashboardSection(
      title: 'Tamu menginap hari ini',
      child: data.stayingGuests.isEmpty
          ? const DashboardEmptyPanel(
              icon: Icons.groups_rounded,
              title: 'Belum ada tamu yang sedang menginap.',
              message: 'Tamu muncul di sini setelah ditandai check-in.',
              compact: true,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                FilterSegmentedTabs(
                  options: <FilterTabOption>[
                    FilterTabOption(label: 'Semua', count: byFilter[0].length),
                    FilterTabOption(
                      label: 'Belum ada laporan',
                      count: byFilter[1].length,
                    ),
                    FilterTabOption(
                      label: 'Sudah lengkap',
                      count: byFilter[2].length,
                    ),
                  ],
                  selectedIndex: _filter,
                  onSelected: (int index) => setState(() => _filter = index),
                ),
                const SizedBox(height: AppSpacing.space12),
                if (shown.isEmpty)
                  const DashboardEmptyPanel(
                    icon: Icons.filter_list_rounded,
                    title: 'Tidak ada tamu di kelompok ini.',
                    message: 'Pilih kelompok lain untuk melihat tamu.',
                    compact: true,
                  ),
                for (final BookingSummary booking in shown) ...<Widget>[
                  GuestListTile(
                    booking: booking,
                    today: data.today,
                    hasReport: data.hasReportToday(booking),
                    onRecord: () => widget.onRecordFor(booking),
                    onOpenLog: () => widget.onOpenLog(booking),
                  ),
                  const SizedBox(height: AppSpacing.space8),
                ],
              ],
            ),
    );
  }
}

class GuestListTile extends StatelessWidget {
  const GuestListTile({
    super.key,
    required this.booking,
    required this.today,
    required this.hasReport,
    required this.onRecord,
    required this.onOpenLog,
  });

  final BookingSummary booking;
  final DateTime today;
  final bool hasReport;
  final VoidCallback onRecord;
  final VoidCallback onOpenLog;

  @override
  Widget build(BuildContext context) {
    final String unit = booking.unitCode == null
        ? ''
        : ' - ${booking.unitCode}';
    final List<String> identity = <String>[
      if (booking.pet.breed.isNotEmpty) booking.pet.breed,
      'Kamar ${booking.roomType}$unit',
    ];

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
                      identity.join(' - '),
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
          Wrap(
            spacing: AppSpacing.space8,
            runSpacing: AppSpacing.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _ReportBadge(hasReport: hasReport),
              StayProgressLine(booking: booking, today: today),
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
            icon: Icons.event_rounded,
            text: stayRange(booking.checkin, booking.checkout),
          ),
          if (booking.hasCareInstructions) ...<Widget>[
            const SizedBox(height: AppSpacing.space12),
            CareNote(text: booking.careInstructions!),
          ],
          const SizedBox(height: AppSpacing.space16),
          hasReport
              ? AppSecondaryButton(label: 'Lihat Log', onPressed: onOpenLog)
              : AppPrimaryButton(label: 'Input Laporan', onPressed: onRecord),
        ],
      ),
    );
  }
}

class _ReportBadge extends StatelessWidget {
  const _ReportBadge({required this.hasReport});

  final bool hasReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space8,
        vertical: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: hasReport ? AppColors.successSurface : AppColors.pendingSurface,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        hasReport ? 'Laporan sudah masuk' : 'Belum ada laporan',
        style: AppTypography.labelMd.copyWith(
          color: hasReport ? AppColors.successText : AppColors.pendingText,
        ),
      ),
    );
  }
}
