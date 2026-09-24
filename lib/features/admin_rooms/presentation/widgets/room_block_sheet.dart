import 'package:flutter/material.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/relative_date.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/room_catalog.dart';
import '../../domain/entities/room_drafts.dart';
import 'room_form_controls.dart';

Future<bool> showRoomBlockSheet(
  BuildContext context, {
  required RoomCatalog catalog,
  required Future<void> Function(RoomBlockDraft draft) onSubmit,
}) async {
  final bool? saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
    ),
    builder: (BuildContext sheetContext) =>
        _RoomBlockSheet(catalog: catalog, onSubmit: onSubmit),
  );
  return saved ?? false;
}

class _RoomBlockSheet extends StatefulWidget {
  const _RoomBlockSheet({required this.catalog, required this.onSubmit});

  final RoomCatalog catalog;
  final Future<void> Function(RoomBlockDraft draft) onSubmit;

  @override
  State<_RoomBlockSheet> createState() => _RoomBlockSheetState();
}

class _RoomBlockSheetState extends State<_RoomBlockSheet> {
  final TextEditingController _purpose = TextEditingController();
  int? _roomId;
  DateTime? _start;
  DateTime? _end;
  int _units = 1;
  Map<BlockField, String> _errors = const <BlockField, String>{};
  String? _serverError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.catalog.rooms.length == 1) {
      _roomId = widget.catalog.rooms.single.id;
    }
  }

  @override
  void dispose() {
    _purpose.dispose();
    super.dispose();
  }

  int get _maxUnits {
    final AdminRoom? room = _roomId == null
        ? null
        : widget.catalog.roomById(_roomId!);
    final int active = room?.activeUnits ?? 1;
    return active < 1 ? 1 : active;
  }

  RoomBlockDraft get _draft => RoomBlockDraft(
    roomId: _roomId,
    dateStart: _start,
    dateEnd: _end,
    blockedUnits: _units,
    purpose: _purpose.text,
    maxUnits: _maxUnits,
    today: widget.catalog.today,
  );

  Future<void> _pickDate({required bool start}) async {
    final DateTime today = widget.catalog.today;
    final DateTime first = start ? today : (_start ?? today);
    final DateTime? current = start ? _start : _end;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current != null && !current.isBefore(first)
          ? current
          : first,
      firstDate: first,
      lastDate: DateTime(today.year + 2, today.month, today.day),
      helpText: start ? 'Tanggal mulai blokir' : 'Tanggal selesai blokir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      if (start) {
        _start = picked;
        if (_end != null && _end!.isBefore(picked)) {
          _end = picked;
        }
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _submit() async {
    final RoomBlockDraft draft = _draft;
    final Map<BlockField, String> errors = draft.validate();
    setState(() {
      _errors = errors;
      _serverError = null;
    });
    if (errors.isNotEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSubmit(draft);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _serverError = error is AppException
            ? error.message
            : 'Blokir belum tersimpan. Coba ulangi sebentar lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<AdminRoom> rooms = widget.catalog.rooms;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenEdge + 4,
          0,
          AppSpacing.screenEdge + 4,
          AppSpacing.space24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text('Blokir unit kamar', style: AppTypography.headlineMd),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              'Unit yang diblokir tidak bisa dipesan selama rentang tanggal ini.',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.space20),
            const AppFieldLabel(text: 'Tipe kamar'),
            const SizedBox(height: AppSpacing.space8),
            OptionChips<int>(
              options: <OptionChipItem<int>>[
                for (final AdminRoom room in rooms)
                  OptionChipItem<int>(
                    value: room.id,
                    label: room.tier.roomType,
                  ),
              ],
              selected: _roomId,
              onSelected: (int id) => setState(() {
                _roomId = id;
                if (_units > _maxUnits) {
                  _units = _maxUnits;
                }
              }),
            ),
            if (_errors[BlockField.room] != null)
              FieldErrorText(text: _errors[BlockField.room]!),
            const SizedBox(height: AppSpacing.space16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _DateField(
                    label: 'Tanggal mulai',
                    value: _start,
                    onTap: () => _pickDate(start: true),
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: _DateField(
                    label: 'Tanggal selesai',
                    value: _end,
                    onTap: () => _pickDate(start: false),
                  ),
                ),
              ],
            ),
            if (_errors[BlockField.dates] != null)
              FieldErrorText(text: _errors[BlockField.dates]!),
            const SizedBox(height: AppSpacing.space16),
            AppFieldLabel(
              text: 'Jumlah unit',
              hint: _roomId == null ? null : 'Maksimal $_maxUnits unit aktif',
            ),
            const SizedBox(height: AppSpacing.space8),
            UnitStepper(
              label: 'Jumlah unit yang diblokir',
              value: _units,
              min: 1,
              max: _maxUnits,
              onChanged: (int value) => setState(() => _units = value),
            ),
            if (_errors[BlockField.units] != null)
              FieldErrorText(text: _errors[BlockField.units]!),
            const SizedBox(height: AppSpacing.space16),
            const AppFieldLabel(text: 'Keperluan', hint: 'Opsional'),
            const SizedBox(height: AppSpacing.space8),
            AppTextField(
              controller: _purpose,
              hintText: 'Contoh: perbaikan AC',
              semanticLabel: 'Keperluan blokir',
              maxLength: RoomBlockDraft.purposeMaxLength,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              errorText: _errors[BlockField.purpose],
            ),
            if (_serverError != null) ...<Widget>[
              const SizedBox(height: AppSpacing.space12),
              FieldErrorText(text: _serverError!),
            ],
            const SizedBox(height: AppSpacing.space24),
            AppPrimaryButton(
              label: 'Simpan blokir',
              isLoading: _saving,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String text = value == null
        ? 'Pilih tanggal'
        : formatShortDate(value!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppFieldLabel(text: label),
        const SizedBox(height: AppSpacing.space8),
        Semantics(
          button: true,
          label: '$label, $text',
          child: ExcludeSemantics(
            child: Material(
              color: AppColors.surfaceRecessed,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.controlAll,
                side: BorderSide(color: AppColors.outlineStrong),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                hoverColor: AppColors.surfaceContainer,
                focusColor: AppColors.surfaceRecessedStrong,
                child: SizedBox(
                  height: AppSpacing.controlHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space12,
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.space8),
                        Expanded(
                          child: Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMd.copyWith(
                              color: value == null
                                  ? AppColors.onSurfaceVariant
                                  : AppColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
