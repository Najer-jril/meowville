import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/reservation_controller.dart';
import '../../controllers/room_controller.dart';
import '../../core/api_client.dart';
import '../../data/models.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';
import 'widgets/availability_calendar.dart';
import 'widgets/block_unit_sheet.dart';
import '../../utils/clock.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final rooms = context.read<RoomController>();
            await rooms.load(withBlocks: true);
            await rooms.refreshAvailability();
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
                Text('Kamar', style: text.headlineLarge),
                SegmentedTabs(
                  labels: const ['Tipe Kamar', 'Ketersediaan'],
                  selected: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
                if (_tab == 0)
                  const _RoomTypeTab()
                else
                  const _AvailabilityTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomTypeTab extends StatelessWidget {
  const _RoomTypeTab();

  @override
  Widget build(BuildContext context) {
    final rooms = context.watch<RoomController>();
    final text = Theme.of(context).textTheme;
    final types = rooms.active;

    if (rooms.loading && types.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (rooms.error != null && types.isEmpty) {
      return ErrorState(
        message: rooms.error!,
        onRetry: () => rooms.load(withBlocks: true),
      );
    }

    return Padding(
      padding: types.isEmpty
          ? EdgeInsets.zero
          : const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        spacing: AppSpacing.lg,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${types.length} tipe kamar',
                  style: text.bodySmall!.copyWith(fontSize: 14),
                ),
              ),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.adminRoomTypeForm),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Tambah'),
              ),
            ],
          ),
          for (final t in types) _RoomTypeCard(type: t),
        ],
      ),
    );
  }
}

class _RoomTypeCard extends StatelessWidget {
  const _RoomTypeCard({required this.type});

  final RoomType type;

  Future<void> _delete(BuildContext context) => runOnce(
    ('delete-room-type', type.id),
    () async {
      final count = context.read<ReservationController>().activeCountFor(type);
      if (count > 0) {
        return showInfoDialog(
          context,
          title: 'Belum bisa dihapus',
          message: 'Masih ada $count reservasi aktif untuk tipe ini.',
        );
      }
      final ok = await showConfirmDialog(
        context,
        title: 'Hapus tipe ${type.name}?',
        message:
            'Tipe ini hilang dari katalog dan tidak bisa dipesan lagi. '
            'Riwayat reservasi yang sudah ada tidak berubah.',
        confirmLabel: 'Hapus',
        destructive: true,
        icon: Icons.delete_outline,
      );
      if (!ok || !context.mounted) return;
      try {
        await context.read<RoomController>().setActive(type, false);
        if (context.mounted) showSnack(context, 'Tipe ${type.name} dihapus');
      } on ApiException catch (e) {
        if (context.mounted) showSnack(context, e.message);
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final shown = type.packages.take(3).toList();
    final more = type.packages.length - shown.length;

    return AppCard(
      child: Column(
        spacing: AppSpacing.md,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                child: AppPhoto(
                  type.photo,
                  size: 88,
                  placeholderIcon: Icons.bed_outlined,
                ),
              ),
              Expanded(
                child: Column(
                  spacing: AppSpacing.xs,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            type.name,
                            style: text.headlineMedium!.copyWith(fontSize: 22),
                          ),
                        ),
                      ],
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: Fmt.rupiah(type.price),
                            style: text.labelLarge!.copyWith(
                              fontSize: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          TextSpan(text: ' / malam', style: text.bodySmall),
                        ],
                      ),
                    ),
                    Row(
                      spacing: AppSpacing.sm,
                      children: [
                        const Icon(
                          Icons.bed_outlined,
                          size: 18,
                          color: AppColors.muted,
                        ),
                        Flexible(
                          child: Text(
                            '${type.unitCount} unit - kode ${type.prefix}',
                            style: text.bodySmall!.copyWith(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opsi',
                icon: const Icon(Icons.more_vert, color: AppColors.muted),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                color: AppColors.surface,
                onSelected: (v) {
                  if (v == 'edit') {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.adminRoomTypeForm,
                      arguments: type,
                    );
                  } else {
                    _delete(context);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_outline,
                        color: AppColors.danger,
                      ),
                      title: Text(
                        'Hapus',
                        style: TextStyle(color: AppColors.danger),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final p in shown) TagChip(p),
              if (more > 0) TagChip('+$more', muted: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvailabilityTab extends StatefulWidget {
  const _AvailabilityTab();

  @override
  State<_AvailabilityTab> createState() => _AvailabilityTabState();
}

class _AvailabilityTabState extends State<_AvailabilityTab> {
  int _type = 0;
  late DateTime _month = DateTime(Clock.today().year, Clock.today().month);

  @override
  void initState() {
    super.initState();
    _loadMonth(_month);
  }

  /// termasuk hari dari bulan sebelum dan sesudah yang ikut tampil di grid
  void _loadMonth(DateTime month) {
    final first = DateTime(month.year, month.month);
    final last = DateTime(month.year, month.month + 1, 0);
    context.read<RoomController>().loadAvailability(
      first.subtract(const Duration(days: 6)),
      last.add(const Duration(days: 6)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rooms = context.watch<RoomController>();
    final text = Theme.of(context).textTheme;
    final types = rooms.active;
    if (types.isEmpty) {
      return const EmptyState(
        icon: Icons.bed_outlined,
        title: 'Belum ada tipe kamar aktif',
        message: 'Tambah tipe kamar terlebih dahulu.',
      );
    }
    if (_type >= types.length) _type = 0;
    final type = types[_type];
    final blocks = rooms.blocksFor(type);

    return Padding(
      padding: blocks.isEmpty
          ? EdgeInsets.zero
          : const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        spacing: AppSpacing.md,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilterChipRow(
            padding: EdgeInsets.zero,
            labels: [for (final t in types) t.name],
            selected: _type,
            onSelected: (i) => setState(() => _type = i),
          ),
          AvailabilityCalendar(
            type: type,
            month: _month,
            onMonthChanged: (m) {
              setState(() => _month = m);
              _loadMonth(m);
            },
            onDayTap: (day) => showDayDetailSheet(context, type, day),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Blokir aktif',
                    style: text.titleLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => showBlockUnitSheet(context, type),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                  ),
                  child: const Text('+ Blokir Unit'),
                ),
              ],
            ),
          ),
          if (blocks.isEmpty)
            AppCard(
              child: Row(
                spacing: AppSpacing.lg,
                children: [
                  const IconBubble(
                    icon: Icons.check_circle_outline,
                    square: true,
                  ),
                  Expanded(
                    child: Text(
                      'Tidak ada unit ${type.name} yang diblokir. '
                      'Semua unit bisa dipesan.',
                      style: text.bodyMedium!.copyWith(color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            )
          else
            for (final b in blocks) _BlockCard(block: b),
        ],
      ),
    );
  }
}

class _BlockCard extends StatelessWidget {
  const _BlockCard({required this.block});

  final UnitBlock block;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(right: AppSpacing.lg),
            child: IconBubble(
              icon: Icons.block,
              color: AppColors.danger,
              background: AppColors.dangerSoft,
              square: true,
              size: 56,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${block.unit} - ${Fmt.range(block.start, block.end)}',
                  style: text.titleLarge!.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  block.reason,
                  style: text.bodySmall!.copyWith(fontSize: 15),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Hapus blokir',
            icon: const Icon(Icons.delete_outline, color: AppColors.muted),
            onPressed: () => runOnce(('remove-block', block.id), () async {
              final rooms = context.read<RoomController>();
              final ok = await showConfirmDialog(
                context,
                title: 'Hapus blokir?',
                message:
                    'Unit ${block.unit} akan tersedia kembali pada '
                    '${Fmt.range(block.start, block.end)}.',
                confirmLabel: 'Hapus',
                destructive: true,
                icon: Icons.delete_outline,
              );
              if (!ok) return;
              try {
                await rooms.removeBlock(block);
                if (context.mounted) showSnack(context, 'Blokir dihapus');
              } on ApiException catch (e) {
                if (context.mounted) showSnack(context, e.message);
              }
            }),
          ),
        ],
      ),
    );
  }
}
