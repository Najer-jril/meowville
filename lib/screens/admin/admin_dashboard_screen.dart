import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';

import '../../data/data.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';
import 'widgets/reservation_actions.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, this.onSeeAllReservations});

  final VoidCallback? onSeeAllReservations;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AdminStore get _store => context.read<AdminStore>();
  int _tab = 0;

  void _openDetail(Reservation r) => Navigator.pushNamed(
    context,
    AppRoutes.adminReservationsDetail,
    arguments: r,
  );

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AdminStore>();
    final text = Theme.of(context).textTheme;

    final pending = store.pending;

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
            // Column(
            //   spacing: AppSpacing.xs,
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     Text('Halo, Admin', style: text.headlineLarge),
            //     Text(
            //       '${Fmt.dateLong(store.today)} - '
            //       '${pending.isEmpty ? 'Tidak ada' : pending.length} '
            //       'reservasi baru masuk',
            //       style: text.bodySmall!.copyWith(fontSize: 14),
            //     ),
            //   ],
            // ),
            Text('Halo, Admin', style: text.headlineLarge),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '${Fmt.dateLong(store.today)} - '
              '${pending.isEmpty ? 'Tidak ada' : pending.length} '
              'reservasi baru masuk',
              style: text.bodySmall!.copyWith(fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.lg),
            SegmentedTabs(
              labels: [
                'Semua',
                'Butuh Respon${pending.isEmpty ? '' : ' (${pending.length})'}',
              ],
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_tab == 0)
              ..._overview(context)
            else
              ..._needsResponse(context, pending),
          ],
        ),
      ),
    );
  }

  List<Widget> _overview(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final checkIns = _store.checkInsToday();
    final arrived = checkIns
        .where((r) => r.status == ReservationStatus.checkedIn)
        .length;
    final staying = _store.staying.length;
    final capacity = _store.totalActiveUnits == 0
        ? 0
        : (staying * 100 / _store.totalActiveUnits).round();
    final types = _store.activeRoomTypes;
    final free = {
      for (final t in types)
        t: () {
          final a = _store.availability(t, _store.today);
          return (a.units - a.occupied - a.blocked).clamp(0, a.units);
        }(),
    };
    final freeTotal = free.values.fold(0, (s, v) => s + v);

    return [
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.15,
        children: [
          _StatCard(
            label: 'Check in hari Ini',
            value: '${checkIns.length}',
            note: checkIns.isEmpty
                ? null
                : '$arrived sudah datang, ${checkIns.length - arrived} belum datang',
          ),
          _StatCard(
            label: 'Check out hari Ini',
            value: '${_store.checkOutsToday().length}',
          ),
          _StatCard(
            label: 'Lagi Menginap',
            value: '$staying',
            note: '$capacity% kapasitas',
          ),
          _StatCard(
            label: 'Kamar Kosong',
            value: '$freeTotal',
            note: [
              for (final e in free.entries)
                if (e.value > 0) '${e.key.name} ${e.value}',
            ].join(' - '),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xl),
      Text(
        'Slot Kamar',
        style: text.titleLarge!.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: AppSpacing.md),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          children: [
            for (var i = 0; i < types.length; i++) ...[
              if (i > 0) const Divider(),
              _StatsRoomRow(type: types[i]),
            ],
          ],
        ),
      ),
    ];
  }

  List<Widget> _needsResponse(BuildContext context, List<Reservation> list) {
    if (list.isEmpty) {
      return const [
        EmptyState(
          icon: Icons.task_alt,
          title: 'Semua beres!',
          message:
              'Tidak ada reservasi yang menunggu keputusan. '
              'Reservasi baru akan muncul di sini.',
        ),
      ];
    }
    final text = Theme.of(context).textTheme;
    return [
      Text(
        'Perlu keputusan Anda',
        style: text.titleLarge!.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: AppSpacing.md),
      for (final r in list) ...[
        _PendingCard(
          reservation: r,
          now: _store.now,
          onTap: () => _openDetail(r),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    ];
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.note});

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: text.bodySmall!.copyWith(fontSize: 14)),
              SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: text.headlineMedium!.copyWith(fontSize: 28, height: 1.1),
              ),
            ],
          ),
          if (note != null && note!.isNotEmpty)
            Text(
              note!,
              style: text.bodySmall!.copyWith(color: AppColors.text),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

class _StatsRoomRow extends StatelessWidget {
  const _StatsRoomRow({required this.type});

  final RoomType type;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AdminStore>();
    final text = Theme.of(context).textTheme;
    final a = store.availability(type, store.today);
    final percent = a.units == 0 ? 0 : (a.occupied * 100 / a.units).round();
    final high = percent >= 80;
    final ready = (a.units - a.occupied - a.blocked).clamp(0, a.units);
    final todayBlocks = store.blocks.where(
      (b) => b.roomType == type && b.covers(store.today),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(type.name, style: text.labelLarge!.copyWith(fontSize: 17)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${Fmt.rupiah(type.price)} / malam',
                  style: text.bodySmall,
                ),
              ),
              Text(
                '${a.occupied} / ${a.units}  ',
                style: text.bodyMedium!.copyWith(fontSize: 14),
              ),
              Text(
                '$percent%',
                style: text.bodyMedium!.copyWith(
                  fontSize: 14,
                  color: high ? AppColors.warning : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (var i = 0; i < a.units; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: i < a.occupied
                          ? (high ? AppColors.secondary : AppColors.primaryDeep)
                          : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            [
              '$ready unit ready',
              for (final b in todayBlocks) '1 unit ditutup: ${b.reason}',
            ].join(' - '),
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.reservation,
    required this.now,
    required this.onTap,
  });

  final Reservation reservation;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final text = Theme.of(context).textTheme;
    final small = text.bodySmall!.copyWith(fontSize: 14);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppPhoto(r.cat.photo, size: 56, radius: 14),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.cat.name,
                      style: text.titleLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${r.cat.breedLabel} - diajukan ${Fmt.ago(r.createdAt, now)}',
                      style: small,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Pemilik : ${r.owner.name}', style: text.bodyMedium),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Kamar : ${r.roomType.name} - '),
                TextSpan(
                  text: 'Unit dipilih ketika diterima',
                  style: small.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
            style: text.bodyMedium,
          ),
          Text(
            '${r.nights} malam dari ${Fmt.range(r.checkIn, r.checkOut)}',
            style: text.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Total ${Fmt.rupiah(r.total)}',
                  style: text.labelLarge!.copyWith(color: AppColors.primary),
                ),
              ),
              if (r.paymentProof != null)
                Flexible(
                  child: TextButton.icon(
                    onPressed: () => showPhotoViewer(context, r.paymentProof!),
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('Lihat Bukti'),
                  ),
                )
              else
                Flexible(
                  child: Text(
                    'Belum kirim bukti bayar',
                    textAlign: TextAlign.right,
                    style: text.bodySmall!.copyWith(color: AppColors.warning),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => showRejectSheet(context, r),
                  style: dangerOutlinedStyle().copyWith(
                    minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
                  ),
                  child: const Text('Tolak'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: r.paymentProof == null
                      ? null
                      : () => showApproveSheet(context, r),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  child: const Text('Setujui'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
