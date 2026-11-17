import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/data.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  static const _periods = ['Bulan Ini', 'Bulan Lalu'];

  AdminStore get _store => context.read<AdminStore>();
  int _period = 0;

  DateTimeRange get _range {
    final t = _store.today;
    return _period == 0
        ? DateTimeRange(start: DateTime(t.year, t.month), end: t)
        : DateTimeRange(
            start: DateTime(t.year, t.month - 1),
            end: DateTime(t.year, t.month, 0),
          );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AdminStore>();
    final text = Theme.of(context).textTheme;
    final range = _range;
    final data = store.report(range.start, range.end);
    final best = data.rows.isEmpty ? null : data.rows.first;
    final maxRevenue = data.rows.fold(
      0,
      (m, r) => r.revenue > m ? r.revenue : m,
    );

    return Scaffold(
      appBar: const SubPageAppBar(title: 'Laporan Pethotel'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilterChipRow(
              labels: _periods,
              selected: _period,
              onSelected: (i) => setState(() => _period = i),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.xs,
                AppSpacing.page,
                0,
              ),
              child: Column(
                spacing: AppSpacing.lg,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    range.start.year == range.end.year
                        ? '${Fmt.range(range.start, range.end)} ${range.end.year}'
                        : '${Fmt.date(range.start)} - ${Fmt.date(range.end)}',
                    style: text.bodySmall!.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (data.isEmpty)
                    EmptyState(
                      icon: Icons.insert_chart_outlined,
                      title: 'Belum ada data',
                      message:
                          'Tidak ada reservasi dikonfirmasi pada periode '
                          'ini. Coba pilih periode lain.',
                    )
                  else ...[
                    Column(
                      spacing: AppSpacing.md,
                      children: [
                        Row(
                          spacing: AppSpacing.md,
                          children: [
                            Expanded(
                              child: _Metric(
                                label: 'Total Omzet',
                                value: Fmt.rupiah(data.revenue),
                                highlight: true,
                              ),
                            ),
                            Expanded(
                              child: _Metric(
                                label: 'Jumlah Booking',
                                value: '${data.bookings}',
                              ),
                            ),
                          ],
                        ),
                        Row(
                          spacing: AppSpacing.md,
                          children: [
                            Expanded(
                              child: _Metric(
                                label: 'Rata-rata Durasi Inap',
                                value:
                                    '${data.avgNights.toStringAsFixed(1).replaceAll('.', ',')} malam',
                              ),
                            ),
                            Expanded(
                              child: _Metric(
                                label: 'Tier Terlaris',
                                value: best!.roomType.name,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Column(
                        spacing: AppSpacing.md,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Per tipe kamar',
                            style: text.titleLarge!.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          AppCard(
                            child: Column(
                              spacing: AppSpacing.lg,
                              children: [
                                for (var i = 0; i < data.rows.length; i++)
                                  _TypeRow(
                                    name: data.rows[i].roomType.name,
                                    bookings: data.rows[i].bookings,
                                    revenue: data.rows[i].revenue,
                                    ratio: maxRevenue == 0
                                        ? 0
                                        : data.rows[i].revenue / maxRevenue,
                                    best: i == 0,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: ConstrainedBox(
        constraints: const BoxConstraints.tightFor(height: AppSizes.metricCard),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: text.bodySmall!.copyWith(fontSize: 14)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: text.titleLarge!.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: highlight ? AppColors.primary : AppColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.name,
    required this.bookings,
    required this.revenue,
    required this.ratio,
    required this.best,
  });

  final String name;
  final int bookings;
  final int revenue;
  final double ratio;
  final bool best;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      spacing: AppSpacing.sm,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: AppSpacing.sm,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    spacing: AppSpacing.sm,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: text.labelLarge!.copyWith(fontSize: 17),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (best)
                        const StatusBadge(
                          label: 'Terlaris',
                          style: BadgeStyle(
                            AppColors.warning,
                            AppColors.secondarySoft,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  Fmt.rupiah(revenue),
                  style: text.labelLarge!.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            Text(
              '$bookings booking',
              style: text.bodySmall!.copyWith(fontSize: 14),
            ),
          ],
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            color: best ? AppColors.secondary : AppColors.primary,
          ),
        ),
      ],
    );
  }
}
