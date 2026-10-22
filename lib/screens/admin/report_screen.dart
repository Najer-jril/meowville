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
      body: ListView(
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.xl,
        ),
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
                const SizedBox(height: AppSpacing.lg),
                if (data.isEmpty)
                  EmptyState(
                    icon: Icons.insert_chart_outlined,
                    title: 'Belum ada data',
                    message:
                        'Tidak ada reservasi dikonfirmasi pada periode '
                        'ini. Coba pilih periode lain.',
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          label: 'Total Omzet',
                          value: Fmt.rupiah(data.revenue),
                          highlight: true,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _Metric(
                          label: 'Jumlah Booking',
                          value: '${data.bookings}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          label: 'Rata-rata Durasi Inap',
                          value:
                              '${data.avgNights.toStringAsFixed(1).replaceAll('.', ',')} malam',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _Metric(
                          label: 'Tier Terlaris',
                          value: best!.roomType.name,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Per tipe kamar',
                    style: text.titleLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < data.rows.length; i++) ...[
                          if (i > 0) const SizedBox(height: AppSpacing.lg),
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
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
      child: SizedBox(
        height: 84,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: text.labelLarge!.copyWith(fontSize: 17),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (best) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const StatusBadge(
                      label: 'Terlaris',
                      style: BadgeStyle(
                        AppColors.warning,
                        AppColors.secondarySoft,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
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
        const SizedBox(height: AppSpacing.sm),
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
