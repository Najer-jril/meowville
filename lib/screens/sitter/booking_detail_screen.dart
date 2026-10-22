import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/data.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';
import '../../routes/app_routes.dart';

class SitterBookingDetailScreen extends StatelessWidget {
  const SitterBookingDetailScreen({
    super.key,
    required this.reservation,
    required this.actor,
  });

  final Reservation reservation;
  final AppUser actor;

  void _openReport(BuildContext context) => Navigator.pushNamed(
    context,
    AppRoutes.sitterDailyReportForm,
    arguments: {'reservation': reservation, 'actor': actor},
  );

  Future<void> _checkIn(BuildContext context) async {
    final r = reservation;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => _ConfirmSheet(
        title: 'Check-in ${r.cat.name}?',
        message:
            'Status menjadi Lagi Nginap. Pastikan kucing sudah '
            'diterima dan kondisinya baik.',
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Check-in'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<AdminStore>().checkIn(r);
      showSnack(context, '${r.cat.name} sudah check-in di unit ${r.unit}');
    }
  }

  Future<void> _checkOut(BuildContext context) async {
    final r = reservation;
    final reported = context.read<AdminStore>().reportToday(r) != null;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => _ConfirmSheet(
        title: 'Check-out ${r.cat.name}?',
        warning: reported ? null : 'Belum ada laporan hari ini.',
        message: 'Reservasi akan ditandai selesai.',
        actions: [
          if (!reported) ...[
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, 'report'),
              child: const Text('Isi Laporan Dulu'),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'checkout'),
            child: Text(reported ? 'Check-out' : 'Tetap Check-out'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (choice == 'report') {
      _openReport(context);
    } else if (choice == 'checkout') {
      context.read<AdminStore>().checkOut(r);
      Navigator.pop(context);
      showSnack(context, '${r.cat.name} sudah check-out');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AdminStore>();
    final r = reservation;
    final staying = r.status == ReservationStatus.checkedIn;
    final report = store.reportToday(r);

    return Scaffold(
      appBar: SubPageAppBar(
        title: 'Detail Menginap',
        trailing: StatusBadge.booking(r.status.key),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.xl,
        ),
        children: [
          _CatCard(r),
          if (staying) ...[
            const SizedBox(height: AppSpacing.md),
            _ReportStatus(report: report, onFill: () => _openReport(context)),
          ],
          const SizedBox(height: AppSpacing.lg),
          _OwnerCard(r.owner),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              children: [
                _CardTitle(
                  Icons.hotel_outlined,
                  'Informasi Menginap',
                  trailing: r.unit == null ? null : 'Kamar ${r.unit}',
                ),
                InfoRow('Tipe kamar', r.roomType.name),
                InfoRow('Unit', r.unit ?? '-'),
                InfoRow('Check-in', Fmt.dateLong(r.checkIn)),
                InfoRow('Check-out', Fmt.dateLong(r.checkOut)),
                InfoRow('Durasi', '${r.nights} malam'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardTitle(
                  Icons.spa_outlined,
                  'Layanan Tambahan',
                  trailing: r.addons.isEmpty
                      ? null
                      : '${r.addons.length} layanan',
                ),
                if (r.addons.isEmpty)
                  Text(
                    'Tidak ada layanan tambahan.',
                    style: Theme.of(context).textTheme.bodySmall!
                        .copyWith(fontSize: 15),
                  )
                else
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final a in r.addons)
                        Chip(
                          avatar: const Icon(
                            Icons.content_cut,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          label: Text(a.name),
                          backgroundColor: AppColors.primarySoft,
                          labelStyle: const TextStyle(
                            color: AppColors.primaryDeep,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: switch (r.status) {
        ReservationStatus.confirmed => BottomActionBar(
          child: FilledButton.icon(
            onPressed: () => _checkIn(context),
            icon: const Icon(Icons.login),
            label: const Text('Check-in'),
          ),
        ),
        ReservationStatus.checkedIn => BottomActionBar(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openReport(context),
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text('Isi Laporan'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _checkOut(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Check-out'),
                ),
              ),
            ],
          ),
        ),
        _ => null,
      },
    );
  }
}

class _CatCard extends StatelessWidget {
  const _CatCard(this.r);

  final Reservation r;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: Row(
        children: [
          AppPhoto(r.cat.photo, size: 72),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.cat.name,
                  style: text.titleLarge!.copyWith(fontSize: 20),
                ),
                Text(
                  '${r.cat.breedLabel} - ${r.cat.weightLabel}',
                  style: text.bodySmall!.copyWith(fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportStatus extends StatelessWidget {
  const _ReportStatus({required this.report, required this.onFill});

  final DailyReport? report;
  final VoidCallback onFill;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final done = report != null;
    final fg = done ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: done ? AppColors.successSoft : AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle_outline : Icons.schedule, color: fg),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              done
                  ? 'Dilaporkan ${report!.reporter.firstName}, '
                        '${Fmt.time(report!.time)} - ${report!.mood}'
                  : 'Belum dilaporkan hari ini',
              style: text.bodyMedium!.copyWith(color: fg),
            ),
          ),
          if (!done)
            TextButton(
              onPressed: onFill,
              style: TextButton.styleFrom(foregroundColor: fg),
              child: const Text('Isi sekarang'),
            )
          else
            const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _OwnerCard extends StatelessWidget {
  const _OwnerCard(this.owner);

  final AppUser owner;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: Row(
        children: [
          UserAvatar(initial: owner.initial, photo: owner.photo, size: 48),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Owner',
                  style: text.labelSmall!.copyWith(letterSpacing: 1.2),
                ),
                Text(owner.name, style: text.titleLarge),
                Text(
                  owner.phone,
                  style: text.bodySmall!.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.icon, this.title, {this.trailing});

  final IconData icon;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: text.titleLarge!.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (trailing != null)
            StatusBadge(
              label: trailing!,
              style: const BadgeStyle(
                AppColors.primaryDeep,
                AppColors.primarySoft,
              ),
            ),
        ],
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.title,
    required this.message,
    required this.actions,
    this.warning,
  });

  final String title;
  final String message;
  final String? warning;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          0,
          AppSpacing.page,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: title),
            if (warning != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        warning!,
                        style: text.labelLarge!.copyWith(
                          fontSize: 15,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: text.bodyLarge!.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.xl),
            ...actions,
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: AppColors.muted),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}
