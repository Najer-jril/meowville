import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';

import '../../controllers/reservation_controller.dart';
import '../../controllers/room_controller.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';
import 'widgets/reservation_actions.dart';
import '../../utils/clock.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, this.onSeeAllReservations});

  final VoidCallback? onSeeAllReservations;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  ReservationController get _reservations =>
      context.read<ReservationController>();
  RoomController get _rooms => context.read<RoomController>();
  int _tab = 0;

  void _openDetail(Reservation r) => Navigator.pushNamed(
    context,
    AppRoutes.adminReservationsDetail,
    arguments: r,
  );

  @override
  Widget build(BuildContext context) {
    final reservations = context.watch<ReservationController>();
    context.watch<RoomController>();
    final text = Theme.of(context).textTheme;

    final pending = reservations.pending;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await reservations.load();
            await _rooms.refreshAvailability();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.xl,
              AppSpacing.page,
              AppSpacing.xl,
            ),
            child: Column(
              spacing: AppSpacing.lg,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Halo, Admin', style: text.headlineLarge),
                Text(
                  '${Fmt.dateLong(Clock.today())} - '
                  '${pending.isEmpty ? 'Tidak ada' : pending.length} '
                  'reservasi baru masuk',
                  style: text.bodySmall!.copyWith(fontSize: 14),
                ),
                SegmentedTabs(
                  labels: [
                    'Semua',
                    'Butuh Respon${pending.isEmpty ? '' : ' (${pending.length})'}',
                  ],
                  selected: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Column(
                    spacing: AppSpacing.xl,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _tab == 0
                        ? _overview(context)
                        : reservations.error != null && pending.isEmpty
                        ? [
                            ErrorState(
                              message: reservations.error!,
                              onRetry: () => reservations.load(),
                            ),
                          ]
                        : _needsResponse(context, pending),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _overview(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final checkIns = _reservations.checkInsToday();
    final arrived = checkIns
        .where((r) => r.status == ReservationStatus.checkedIn)
        .length;
    final staying = _reservations.staying.length;
    final capacity = _rooms.totalActiveUnits == 0
        ? 0
        : (staying * 100 / _rooms.totalActiveUnits).round();
    final types = _rooms.active;
    final free = {
      for (final t in types)
        t: () {
          final a = _rooms.availability(t, Clock.today());
          return (a.units - a.occupied - a.blocked).clamp(0, a.units);
        }(),
    };
    final freeTotal = free.values.fold(0, (s, v) => s + v);

    return [
      // Baris berisi dua kartu yang tingginya mengikuti isi, supaya teks
      // tidak terpotong saat ukuran font sistem diperbesar.
      _StatGrid(
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
            value: '${_reservations.checkOutsToday().length}',
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
      Column(
        spacing: AppSpacing.md,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Slot Kamar',
            style: text.titleLarge!.copyWith(fontWeight: FontWeight.w700),
          ),
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
        ],
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
      Column(
        spacing: AppSpacing.md,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Perlu keputusan Anda',
            style: text.titleLarge!.copyWith(fontWeight: FontWeight.w700),
          ),
          Column(
            spacing: AppSpacing.lg,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final r in list)
                _PendingCard(
                  reservation: r,
                  now: Clock.now(),
                  onTap: () => _openDetail(r),
                ),
            ],
          ),
        ],
      ),
    ];
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    spacing: AppSpacing.md,
    children: [
      for (var i = 0; i < children.length; i += 2)
        IntrinsicHeight(
          child: Row(
            spacing: AppSpacing.md,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              Expanded(
                child: i + 1 < children.length
                    ? children[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
    ],
  );
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.statCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              spacing: AppSpacing.xs,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: text.bodySmall!.copyWith(fontSize: 14)),
                Text(
                  value,
                  style: text.headlineMedium!.copyWith(
                    fontSize: 28,
                    height: 1.1,
                  ),
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
      ),
    );
  }
}

class _StatsRoomRow extends StatelessWidget {
  const _StatsRoomRow({required this.type});

  final RoomType type;

  @override
  Widget build(BuildContext context) {
    final rooms = context.watch<RoomController>();
    final text = Theme.of(context).textTheme;
    final a = rooms.availability(type, Clock.today());
    final percent = a.units == 0 ? 0 : (a.occupied * 100 / a.units).round();
    final high = percent >= 80;
    final ready = (a.units - a.occupied - a.blocked).clamp(0, a.units);
    final todayBlocks = rooms.blocks.where(
      (b) => b.roomType == type && b.covers(Clock.today()),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        spacing: AppSpacing.sm,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Text(
                    type.name,
                    style: text.labelLarge!.copyWith(fontSize: 17),
                  ),
                ),
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
          ),
          Row(
            spacing: AppSpacing.xs,
            children: [
              for (var i = 0; i < a.units; i++)
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
          ),
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
        spacing: AppSpacing.md,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: AppSpacing.md,
            children: [
              AppPhoto(r.cat.photo, size: 56, radius: 14),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
            ],
          ),
          Column(
            spacing: AppSpacing.sm,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Total ${Fmt.rupiah(r.total)}',
                      style: text.labelLarge!.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (r.paymentProof != null)
                    Flexible(
                      child: TextButton.icon(
                        onPressed: () =>
                            showPhotoViewer(context, r.paymentProof!),
                        icon: const Icon(Icons.receipt_long_outlined, size: 18),
                        label: const Text('Lihat Bukti'),
                      ),
                    )
                  else
                    Flexible(
                      child: Text(
                        'Belum kirim bukti bayar',
                        textAlign: TextAlign.right,
                        style: text.bodySmall!.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                ],
              ),
              Row(
                spacing: AppSpacing.md,
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
                  Expanded(
                    child: FilledButton(
                      onPressed: r.paymentProof == null
                          ? null
                          : () => showApproveSheet(context, r),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                      ),
                      child: const Text('Setujui'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
