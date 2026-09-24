import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../dashboard/presentation/providers/dashboard_controller.dart';
import '../../../dashboard/presentation/widgets/dashboard_state_panels.dart';
import '../../../dashboard/presentation/widgets/dashboard_view.dart';
import '../../../dashboard/presentation/widgets/filter_segmented_tabs.dart';
import '../../domain/entities/room_catalog.dart';
import '../../domain/entities/room_drafts.dart';
import '../../domain/repositories/admin_room_repository.dart';
import '../../domain/usecases/room_usecases.dart';
import '../admin_room_routes.dart';
import '../providers/room_mutation_controller.dart';
import '../widgets/room_block_sheet.dart';
import '../widgets/room_cards.dart';

typedef RoomCatalogController = DashboardController<RoomCatalog>;

class AdminRoomsScreen extends StatelessWidget {
  const AdminRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<RoomCatalogController>(
          create: (BuildContext context) => RoomCatalogController(
            LoadRoomCatalogUseCase(
              context.read<AdminRoomRepository>(),
              context.read<Clock>(),
            ).call,
            fallbackMessage:
                'Data kamar gagal dimuat. Coba ulangi sebentar lagi.',
          ),
        ),
        ChangeNotifierProvider<RoomMutationController>(
          create: (_) => RoomMutationController(),
        ),
      ],
      child: DashboardView<RoomCatalog>(
        loadingLabel: 'Memuat data kamar...',
        errorTitle: 'Data kamar belum bisa dimuat',
        skeletonHeights: const <double>[48, 220, 220, 220],
        builder: (BuildContext context, RoomCatalog catalog) => <Widget>[
          _RoomsBody(catalog: catalog),
        ],
      ),
    );
  }
}

class _RoomsBody extends StatefulWidget {
  const _RoomsBody({required this.catalog});

  final RoomCatalog catalog;

  @override
  State<_RoomsBody> createState() => _RoomsBodyState();
}

class _RoomsBodyState extends State<_RoomsBody> {
  static const int _typesTab = 0;

  int _tab = _typesTab;

  Future<void> _openForm(String route) async {
    final RoomCatalogController controller = context
        .read<RoomCatalogController>();
    await context.push(route);
    // Tier bisa berubah atau terhapus di form, jadi data ditarik ulang.
    await controller.refresh();
  }

  Future<void> _createBlock() async {
    final RoomCatalogController controller = context
        .read<RoomCatalogController>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final CreateRoomBlockUseCase create = CreateRoomBlockUseCase(
      context.read<AdminRoomRepository>(),
    );
    final String? adminId = context.read<AuthNotifier>().user?.id;

    final bool saved = await showRoomBlockSheet(
      context,
      catalog: widget.catalog,
      onSubmit: (RoomBlockDraft draft) =>
          create(draft: draft, adminId: adminId),
    );
    if (!saved) {
      return;
    }
    await controller.refresh();
    messenger.showSnackBar(
      const SnackBar(content: Text('Blokir unit tersimpan.')),
    );
  }

  Future<void> _deleteBlock(RoomBlock block) async {
    final RoomCatalogController controller = context
        .read<RoomCatalogController>();
    final RoomMutationController mutation = context
        .read<RoomMutationController>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final DeleteRoomBlockUseCase delete = DeleteRoomBlockUseCase(
      context.read<AdminRoomRepository>(),
    );

    final bool confirmed = await showAppConfirmDialog(
      context,
      title: 'Hapus blokir ${block.roomType}?',
      body:
          '${block.blockedUnits} unit ${block.roomType} untuk '
          '${blockRangeLabel(block)} akan kembali bisa dipesan.',
      confirmLabel: 'Ya, hapus blokir',
      isDestructive: true,
    );
    if (!confirmed) {
      return;
    }
    final bool saved = await mutation.run(
      'block-${block.id}',
      () => delete(block.id),
    );
    await controller.refresh();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Blokir ${block.roomType} dihapus.'
              : mutation.errorMessage ??
                    'Blokir belum terhapus. Coba ulangi sebentar lagi.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final RoomCatalog catalog = widget.catalog;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppPageHeader(
          title: 'Kamar',
          subtitle: 'Tarif, jumlah unit, dan penutupan unit tiap tier.',
        ),
        FilterSegmentedTabs(
          options: <FilterTabOption>[
            const FilterTabOption(label: 'Tipe kamar'),
            FilterTabOption(
              label: 'Blokir unit',
              count: catalog.blocks.isEmpty ? null : catalog.blocks.length,
            ),
          ],
          selectedIndex: _tab,
          onSelected: (int index) => setState(() => _tab = index),
        ),
        const SizedBox(height: AppSpacing.space20),
        if (_tab == _typesTab)
          _TypesTab(
            catalog: catalog,
            onEdit: (AdminRoom room) =>
                _openForm(AdminRoomRoutes.edit(room.id)),
            onCreate: () => _openForm(AdminRoomRoutes.create),
          )
        else
          _BlocksTab(
            catalog: catalog,
            onCreate: _createBlock,
            onDelete: _deleteBlock,
          ),
      ],
    );
  }
}

class _TypesTab extends StatelessWidget {
  const _TypesTab({
    required this.catalog,
    required this.onEdit,
    required this.onCreate,
  });

  final RoomCatalog catalog;
  final ValueChanged<AdminRoom> onEdit;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    if (catalog.rooms.isEmpty) {
      return DashboardEmptyPanel(
        icon: Icons.bed_rounded,
        title: 'Belum ada tipe kamar',
        message:
            'Tambahkan Standard, Deluxe, atau Suite beserta tarif dan '
            'jumlah unitnya agar pawrent bisa memesan.',
        actionLabel: 'Tambah tipe kamar',
        onAction: onCreate,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < catalog.rooms.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.space16),
          RoomTierCard(
            room: catalog.rooms[i],
            onEdit: () => onEdit(catalog.rooms[i]),
          ),
        ],
        if (catalog.missingTypes.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.space20),
          AppSecondaryButton(
            label: 'Tambah tipe kamar',
            leadingIcon: Icons.add_rounded,
            onPressed: onCreate,
          ),
        ],
      ],
    );
  }
}

class _BlocksTab extends StatelessWidget {
  const _BlocksTab({
    required this.catalog,
    required this.onCreate,
    required this.onDelete,
  });

  final RoomCatalog catalog;
  final VoidCallback onCreate;
  final ValueChanged<RoomBlock> onDelete;

  @override
  Widget build(BuildContext context) {
    if (catalog.rooms.isEmpty) {
      return const DashboardEmptyPanel(
        icon: Icons.lock_outline_rounded,
        title: 'Belum ada unit untuk diblokir',
        message: 'Tambahkan tipe kamar dulu di tab Tipe kamar.',
      );
    }
    final RoomMutationController mutation = context
        .watch<RoomMutationController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppPrimaryButton(
          label: 'Blokir unit',
          leadingIcon: Icons.lock_outline_rounded,
          onPressed: mutation.isBusy ? null : onCreate,
        ),
        const SizedBox(height: AppSpacing.space20),
        if (catalog.blocks.isEmpty)
          const DashboardEmptyPanel(
            icon: Icons.event_available_rounded,
            title: 'Tidak ada unit yang ditutup',
            message:
                'Semua unit aktif bisa dipesan. Blokir unit saat ada '
                'perawatan atau renovasi.',
          )
        else
          for (int i = 0; i < catalog.blocks.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.space12),
            RoomBlockCard(
              block: catalog.blocks[i],
              today: catalog.today,
              deleting: mutation.busyKey == 'block-${catalog.blocks[i].id}',
              onDelete: mutation.isBusy
                  ? null
                  : () => onDelete(catalog.blocks[i]),
            ),
          ],
      ],
    );
  }
}
