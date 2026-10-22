import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/data.dart';
import '../../../data/models.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/format.dart';
import '../../../widgets/common.dart';

BadgeStyle _remainingStyle(int remaining) {
  if (remaining == 0) {
    return const BadgeStyle(AppColors.danger, AppColors.dangerSoft);
  }
  if (remaining == 1) {
    return const BadgeStyle(AppColors.warning, AppColors.warningSoft);
  }
  return const BadgeStyle(AppColors.primary, AppColors.primarySoft);
}

class AvailabilityCalendar extends StatelessWidget {
  const AvailabilityCalendar({
    super.key,
    required this.type,
    required this.month,
    required this.onMonthChanged,
    required this.onDayTap,
  });

  final RoomType type;
  final DateTime month;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDayTap;

  static const _weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AdminStore>();
    final text = Theme.of(context).textTheme;
    final first = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday - 1;
    final cells = lead + daysInMonth;
    final rows = (cells / 7).ceil();
    final thisMonth = DateTime(store.today.year, store.today.month);

    Widget navButton(IconData icon, String tip, VoidCallback? onTap) =>
        IconButton.filledTonal(
          tooltip: tip,
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceAlt,
            foregroundColor: AppColors.text,
          ),
          icon: Icon(icon),
        );

    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  Fmt.monthYear(month),
                  style: text.titleLarge!.copyWith(fontSize: 20),
                ),
              ),
              navButton(
                Icons.chevron_left,
                'Bulan sebelumnya',
                month.isAfter(thisMonth)
                    ? () =>
                          onMonthChanged(DateTime(month.year, month.month - 1))
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              navButton(
                Icons.chevron_right,
                'Bulan berikutnya',
                () => onMonthChanged(DateTime(month.year, month.month + 1)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final w in _weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: text.bodySmall!.copyWith(fontSize: 14),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var row = 0; row < rows; row++)
            Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: _cell(
                      context,
                      store,
                      row * 7 + col - lead + 1,
                      daysInMonth,
                    ),
                  ),
              ],
            ),
          const Divider(height: AppSpacing.xl),
          const Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _Legend(AppColors.primary, 'Ready'),
              _Legend(AppColors.warning, 'Tinggal 1'),
              _Legend(AppColors.danger, 'Full'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    AdminStore store,
    int day,
    int daysInMonth,
  ) {
    if (day < 1 || day > daysInMonth) return const SizedBox(height: 60);
    final date = DateTime(month.year, month.month, day);
    final past = date.isBefore(store.today);
    final isToday = date == store.today;
    final remaining = past ? null : store.availability(type, date).remaining;
    final style = remaining == null ? null : _remainingStyle(remaining);

    return InkWell(
      onTap: past ? null : () => onDayTap(date),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 60,
        margin: const EdgeInsets.all(2),
        decoration: isToday
            ? BoxDecoration(
                border: Border.all(color: AppColors.primaryDeep, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: past
                    ? AppColors.muted
                    : (isToday ? AppColors.primaryDeep : AppColors.text),
              ),
            ),
            const SizedBox(height: 4),
            if (style != null)
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: style.bg,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$remaining',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: style.fg,
                  ),
                ),
              )
            else
              const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

Future<void> showDayDetailSheet(
  BuildContext context,
  RoomType type,
  DateTime day,
) {
  final a = context.read<AdminStore>().availability(type, day);
  final style = _remainingStyle(a.remaining);

  return showModalBottomSheet<void>(
    context: context,
    builder: (ctx) {
      final text = Theme.of(ctx).textTheme;
      Widget row(Color dot, String label, int value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: text.bodyLarge!.copyWith(color: AppColors.muted),
              ),
            ),
            Text('$value', style: text.labelLarge),
          ],
        ),
      );

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetHeader(
                title: 'Rincian ${Fmt.dayMonth(day)}',
                subtitle: 'Kamar ${type.name}',
              ),
              const SizedBox(height: AppSpacing.md),
              row(AppColors.primaryDeep, 'Unit aktif', a.units),
              row(AppColors.info, 'Terisi', a.occupied),
              row(AppColors.warning, 'Menunggu konfirmasi', a.pending),
              row(AppColors.danger, 'Diblokir', a.blocked),
              const Divider(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(child: Text('Sisa', style: text.labelLarge)),
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: style.bg,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${a.remaining}',
                      style: text.labelLarge!.copyWith(color: style.fg),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
