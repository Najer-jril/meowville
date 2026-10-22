import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/data.dart';
import '../../data/models.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';
import 'widgets/availability_calendar.dart';
import 'widgets/block_unit_sheet.dart';

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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.xl,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          children: [
            Text('Kamar', style: text.headlineLarge),
            const SizedBox(height: AppSpacing.lg),
            SegmentedTabs(
              labels: const ['Tipe Kamar', 'Ketersediaan'],
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_tab == 0) const _RoomTypeTab() else const _AvailabilityTab(),
          ],
        ),
      ),
    );
  }
}

class _RoomTypeTab extends StatelessWidget {
  const _RoomTypeTab();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AdminStore>();
    final text = Theme.of(context).textTheme;
    final types = store.activeRoomTypes;

    return Column(
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
        const SizedBox(height: AppSpacing.lg),
        for (final t in types) ...[
          _RoomTypeCard(type: t),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}

class _RoomTypeCard extends StatelessWidget {
  const _RoomTypeCard({required this.type});

  final RoomType type;

  Future<void> _delete(BuildContext context) async {
    final store = context.read<AdminStore>();
    final count = store.activeReservationCount(type);
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
    if (ok) {
      store.setRoomTypeActive(type, false);
      if (context.mounted) showSnack(context, 'Tipe ${type.name} dihapus');
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final shown = type.packages.take(3).toList();
    final more = type.packages.length - shown.length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppPhoto(
                type.photo,
                size: 88,
                placeholderIcon: Icons.bed_outlined,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
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
                    const SizedBox(height: AppSpacing.xs),
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
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.bed_outlined,
                          size: 18,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 6),
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
          const SizedBox(height: AppSpacing.md),
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
  AdminStore get _store => context.read<AdminStore>();
  int _type = 0;
  late DateTime _month = DateTime(_store.today.year, _store.today.month);

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AdminStore>();
    final text = Theme.of(context).textTheme;
    final types = store.activeRoomTypes;
    if (types.isEmpty) {
      return const EmptyState(
        icon: Icons.bed_outlined,
        title: 'Belum ada tipe kamar aktif',
        message: 'Tambah tipe kamar terlebih dahulu.',
      );
    }
    if (_type >= types.length) _type = 0;
    final type = types[_type];
    final blocks = store.blocksFor(type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterChipRow(
          padding: EdgeInsets.zero,
          labels: [for (final t in types) t.name],
          selected: _type,
          onSelected: (i) => setState(() => _type = i),
        ),
        const SizedBox(height: AppSpacing.md),
        AvailabilityCalendar(
          type: type,
          month: _month,
          onMonthChanged: (m) => setState(() => _month = m),
          onDayTap: (day) => showDayDetailSheet(context, type, day),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: Text(
                'Blokir aktif',
                style: text.titleLarge!.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            OutlinedButton(
              onPressed: () => showBlockUnitSheet(context, type),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              ),
              child: const Text('+ Blokir Unit'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (blocks.isEmpty)
          AppCard(
            child: Row(
              children: [
                const IconBubble(
                  icon: Icons.check_circle_outline,
                  square: true,
                ),
                const SizedBox(width: AppSpacing.lg),
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
          for (final b in blocks) ...[
            _BlockCard(block: b),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
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
          const IconBubble(
            icon: Icons.block,
            color: AppColors.danger,
            background: AppColors.dangerSoft,
            square: true,
            size: 56,
          ),
          const SizedBox(width: AppSpacing.lg),
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
            onPressed: () async {
              final store = context.read<AdminStore>();
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
              if (ok) {
                store.removeBlock(block);
                if (context.mounted) showSnack(context, 'Blokir dihapus');
              }
            },
          ),
        ],
      ),
    );
  }
}
