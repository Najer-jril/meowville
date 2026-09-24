import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/relative_date.dart';
import '../../../../core/widgets/app_back_link.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../dashboard/presentation/widgets/dashboard_state_panels.dart';
import '../../../dashboard/presentation/widgets/dashboard_view.dart';
import '../../domain/entities/room_catalog.dart';
import '../../domain/entities/room_drafts.dart';
import '../../domain/entities/room_type.dart';
import '../../domain/repositories/admin_room_repository.dart';
import '../../domain/usecases/room_usecases.dart';
import '../admin_room_routes.dart';
import '../providers/room_mutation_controller.dart';
import '../widgets/room_form_controls.dart';
import 'admin_rooms_screen.dart';

class AdminRoomFormScreen extends StatelessWidget {
  const AdminRoomFormScreen({super.key, this.roomId});

  final int? roomId;

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
      child: Builder(
        builder: (BuildContext context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppBackLink(label: 'Daftar kamar', onBack: () => _leave(context)),
            Expanded(
              child: DashboardView<RoomCatalog>(
                loadingLabel: 'Memuat data kamar...',
                errorTitle: 'Data kamar belum bisa dimuat',
                skeletonHeights: const <double>[56, 48, 120, 120, 48, 64],
                builder: (BuildContext context, RoomCatalog catalog) =>
                    <Widget>[_RoomForm(catalog: catalog, roomId: roomId)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _leave(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AdminRoomRoutes.list);
  }
}

class _RoomForm extends StatefulWidget {
  const _RoomForm({required this.catalog, required this.roomId});

  final RoomCatalog catalog;
  final int? roomId;

  @override
  State<_RoomForm> createState() => _RoomFormState();
}

class _RoomFormState extends State<_RoomForm> {
  late final AdminRoom? _room = widget.roomId == null
      ? null
      : widget.catalog.roomById(widget.roomId!);
  late final TextEditingController _typeLabel = TextEditingController(
    text: _room?.tier.roomType ?? '',
  );
  late final TextEditingController _description = TextEditingController(
    text: _room?.tier.description ?? '',
  );
  late final TextEditingController _included = TextEditingController(
    text: _room?.tier.includedServices ?? '',
  );
  late final TextEditingController _price = TextEditingController(
    text: _room == null ? '' : _room.tier.pricePerNight.round().toString(),
  );
  late RoomType? _type =
      _room?.type ??
      (widget.catalog.missingTypes.length == 1
          ? widget.catalog.missingTypes.single
          : null);
  late int _units = _room == null
      ? 1
      : (_room.activeUnits < _minUnits ? _minUnits : _room.activeUnits);
  Map<RoomField, String> _errors = const <RoomField, String>{};

  static const int _maxUnits = 99;

  bool get _isEdit => widget.roomId != null;
  int get _minUnits {
    final int reserved = _room?.activeReservations ?? 0;
    return reserved < 1 ? 1 : reserved;
  }

  @override
  void dispose() {
    _typeLabel.dispose();
    _description.dispose();
    _included.dispose();
    _price.dispose();
    super.dispose();
  }

  RoomDraft get _draft => RoomDraft(
    type: _type,
    description: _description.text,
    includedServices: _included.text,
    priceText: _price.text,
    unitCount: _units,
    minUnits: _minUnits,
  );

  Future<void> _save() async {
    final RoomDraft draft = _draft;
    final Map<RoomField, String> errors = draft.validate();
    setState(() => _errors = errors);
    if (errors.isNotEmpty) {
      return;
    }
    final RoomMutationController mutation = context
        .read<RoomMutationController>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final SaveRoomUseCase save = SaveRoomUseCase(
      context.read<AdminRoomRepository>(),
      context.read<Clock>(),
    );

    final bool saved = await mutation.run(
      'save',
      () => save(roomId: widget.roomId, draft: draft),
    );
    if (!saved || !mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _isEdit
              ? 'Perubahan ${_type!.wireValue} tersimpan.'
              : 'Tipe ${_type!.wireValue} ditambahkan.',
        ),
      ),
    );
    _leave(context);
  }

  Future<void> _delete(AdminRoom room) async {
    final RoomMutationController mutation = context
        .read<RoomMutationController>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final DeleteRoomUseCase delete = DeleteRoomUseCase(
      context.read<AdminRoomRepository>(),
    );

    final bool confirmed = await showAppConfirmDialog(
      context,
      title: 'Hapus tipe ${room.tier.roomType}?',
      body:
          'Tipe ${room.tier.roomType} beserta ${room.units.length} unit dan '
          'semua blokirnya akan dihapus. Tipe yang sudah punya riwayat '
          'reservasi tidak bisa dihapus.',
      confirmLabel: 'Ya, hapus tipe',
      isDestructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    final bool deleted = await mutation.run('delete', () => delete(room.id));
    if (!deleted || !mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text('Tipe ${room.tier.roomType} dihapus.')),
    );
    _leave(context);
  }

  @override
  Widget build(BuildContext context) {
    final AdminRoom? room = _room;
    if (_isEdit && room == null) {
      return const DashboardEmptyPanel(
        icon: Icons.search_off_rounded,
        title: 'Tipe kamar tidak ditemukan',
        message: 'Tipe ini mungkin sudah dihapus. Kembali ke daftar kamar.',
      );
    }
    final List<RoomType> missing = widget.catalog.missingTypes;
    if (!_isEdit && missing.isEmpty) {
      return const DashboardEmptyPanel(
        icon: Icons.bed_rounded,
        title: 'Ketiga tipe kamar sudah ada',
        message:
            'Standard, Deluxe, dan Suite sudah terdaftar. Ubah tipe yang ada '
            'dari daftar kamar.',
      );
    }

    final RoomMutationController mutation = context
        .watch<RoomMutationController>();
    final bool busy = mutation.isBusy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            _isEdit ? 'Ubah kamar ${room!.tier.roomType}' : 'Tambah tipe kamar',
            style: AppTypography.headlineLg,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          _isEdit
              ? 'Harga baru hanya berlaku untuk reservasi berikutnya. '
                    'Reservasi yang sudah dibuat tetap memakai harga lamanya.'
              : 'Satu tier per jenis. Unit baru diberi kode urut otomatis.',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.space24),
        AppFieldLabel(
          text: 'Tipe kamar',
          hint: _isEdit ? 'Tidak bisa diubah' : null,
        ),
        const SizedBox(height: AppSpacing.space8),
        if (_isEdit)
          AppTextField(
            controller: _typeLabel,
            hintText: '',
            enabled: false,
            icon: Icons.lock_outline_rounded,
            iconSide: AppTextFieldIconSide.trailing,
            semanticLabel: 'Tipe kamar, tidak bisa diubah',
          )
        else ...<Widget>[
          OptionChips<RoomType>(
            options: <OptionChipItem<RoomType>>[
              for (final RoomType type in missing)
                OptionChipItem<RoomType>(value: type, label: type.wireValue),
            ],
            selected: _type,
            onSelected: (RoomType type) => setState(() => _type = type),
          ),
          if (_errors[RoomField.type] != null)
            FieldErrorText(text: _errors[RoomField.type]!),
        ],
        const SizedBox(height: AppSpacing.space20),
        const AppFieldLabel(text: 'Deskripsi', hint: 'Opsional'),
        const SizedBox(height: AppSpacing.space8),
        AppTextField(
          controller: _description,
          hintText: 'Ukuran, suasana, atau fasilitas fisik kamar',
          semanticLabel: 'Deskripsi kamar',
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: AppSpacing.space20),
        const AppFieldLabel(text: 'Paket layanan bawaan'),
        const SizedBox(height: AppSpacing.space8),
        AppTextField(
          controller: _included,
          hintText: 'Pisahkan dengan koma. Contoh: CCTV, playtime harian',
          semanticLabel: 'Paket layanan bawaan',
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          textCapitalization: TextCapitalization.sentences,
          errorText: _errors[RoomField.includedServices],
        ),
        const SizedBox(height: AppSpacing.space20),
        const AppFieldLabel(text: 'Harga per malam (Rp)'),
        const SizedBox(height: AppSpacing.space8),
        AppTextField(
          controller: _price,
          hintText: 'Contoh: 150000',
          semanticLabel: 'Harga per malam dalam rupiah',
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          errorText: _errors[RoomField.price],
          onChanged: (_) => setState(() {}),
        ),
        if (_draft.price != null && _errors[RoomField.price] == null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space4),
            child: Text(
              'Tampil sebagai ${formatRupiah(_draft.price!)} / malam',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.space20),
        AppFieldLabel(
          text: 'Jumlah unit',
          hint: _isEdit && _minUnits > 1
              ? 'Minimal $_minUnits, jumlah reservasi aktif'
              : null,
        ),
        const SizedBox(height: AppSpacing.space8),
        UnitStepper(
          label: 'Jumlah unit aktif',
          value: _units,
          min: _minUnits,
          max: _maxUnits,
          onChanged: (int value) => setState(() => _units = value),
        ),
        if (_errors[RoomField.units] != null)
          FieldErrorText(text: _errors[RoomField.units]!),
        if (mutation.errorMessage != null) ...<Widget>[
          const SizedBox(height: AppSpacing.space16),
          FieldErrorText(text: mutation.errorMessage!),
        ],
        const SizedBox(height: AppSpacing.space24),
        AppPrimaryButton(
          label: _isEdit ? 'Simpan perubahan' : 'Tambah tipe kamar',
          isLoading: mutation.busyKey == 'save',
          onPressed: busy ? null : _save,
        ),
        if (_isEdit) ...<Widget>[
          const SizedBox(height: AppSpacing.space32),
          const Divider(color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.space16),
          Text('Hapus tipe kamar', style: AppTypography.labelLg),
          const SizedBox(height: AppSpacing.space4),
          Text(
            'Hanya untuk tier yang belum pernah dipesan. Tier dengan riwayat '
            'reservasi tetap tersimpan agar laporan lama tidak rusak.',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.space12),
          AppSecondaryButton(
            label: 'Hapus tipe ${room!.tier.roomType}',
            leadingIcon: Icons.delete_outline_rounded,
            isLoading: mutation.busyKey == 'delete',
            onPressed: busy ? null : () => _delete(room),
          ),
        ],
      ],
    );
  }
}
