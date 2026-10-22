import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../data/data.dart';
import '../../data/models.dart';
import '../../theme/app_assets.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';

class RoomTypeFormScreen extends StatefulWidget {
  const RoomTypeFormScreen({super.key, this.existing});

  final RoomType? existing;

  @override
  State<RoomTypeFormScreen> createState() => _RoomTypeFormScreenState();
}

class _RoomTypeFormScreenState extends State<RoomTypeFormScreen> {
  AdminStore get _store => context.read<AdminStore>();
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _prefix = TextEditingController(text: widget.existing?.prefix);
  late final _desc = TextEditingController(text: widget.existing?.description);
  late final _price = TextEditingController(
    text: widget.existing?.price.toString(),
  );
  late final List<String> _facilities = [...?widget.existing?.facilities];
  late final List<String> _packages = [...?widget.existing?.packages];
  late int _units = widget.existing?.unitCount ?? 1;
  late String? _photo = widget.existing?.photo;
  bool _submitted = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    for (final c in [_desc, _prefix]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _prefix, _desc, _price]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    const options = [
      AppImages.roomStandard,
      AppImages.roomDeluxe,
      AppImages.roomSuite,
      AppImages.roomPresidential,
    ];
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHeader(
                title: 'Pilih foto kamar',
                subtitle: 'Contoh foto dari galeri',
              ),
              const SizedBox(height: AppSpacing.lg),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.4,
                children: [
                  for (final p in options)
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx, p),
                      child: LayoutBuilder(
                        builder: (_, c) => AppPhoto(
                          p,
                          size: c.maxWidth,
                          height: c.maxHeight,
                          placeholderIcon: Icons.bed_outlined,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _photo = picked);
  }

  Future<void> _addChip(List<String> target, String title) async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _ChipInputDialog(title: title),
    );
    if (!mounted) return;
    final v = value?.trim() ?? '';
    if (v.isNotEmpty && !target.contains(v)) setState(() => target.add(v));
  }

  void _save() {
    setState(() => _submitted = true);
    final valid = _formKey.currentState!.validate();
    if (!valid || _packages.isEmpty) return;
    _store.saveRoomType(
      existing: widget.existing,
      name: _name.text.trim(),
      prefix: _prefix.text.trim().toUpperCase(),
      description: _desc.text.trim(),
      price: int.parse(_price.text),
      unitCount: _units,
      facilities: _facilities,
      packages: _packages,
      photo: _photo,
    );
    Navigator.pop(context);
    showSnack(
      context,
      _isEdit ? 'Tipe kamar disimpan' : 'Tipe kamar ditambahkan',
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final prefix = _prefix.text.trim().toUpperCase();
    final codes = prefix.isEmpty
        ? null
        : List.generate(
                _units.clamp(1, 3),
                (i) => '$prefix${i + 1}',
              ).join(', ') +
              (_units > 3 ? ', ...' : '');

    return Scaffold(
      appBar: SubPageAppBar(
        title: _isEdit ? 'Edit Tipe Kamar' : 'Tambah Tipe Kamar',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FieldLabel('Foto Kamar'),
                  _PhotoBox(photo: _photo, onTap: _pickPhoto),
                  const SizedBox(height: AppSpacing.xl),
                  const FieldLabel('Nama Tipe'),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'misal, Deluxe'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama tipe wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const FieldLabel('Kode Awalan Unit'),
                  TextFormField(
                    controller: _prefix,
                    enabled: !_isEdit,
                    maxLength: 3,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'misal, D',
                      counterText: '',
                      suffixIcon: _isEdit
                          ? const Icon(
                              Icons.lock_outline,
                              color: AppColors.muted,
                            )
                          : null,
                      helperText: _isEdit
                          ? 'Tidak bisa diubah'
                          : 'Dipakai untuk kode unit: ${codes ?? 'D1, D2, D3'}',
                    ),
                    validator: (v) {
                      if (_isEdit) return null;
                      if (v == null || v.trim().isEmpty) {
                        return 'Kode awalan wajib diisi';
                      }
                      if (_store.prefixTaken(v.trim())) {
                        return 'Kode ${v.trim().toUpperCase()} sudah dipakai '
                            'tipe lain';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FieldLabel('Deskripsi', trailing: '${_desc.text.length}/200'),
                  TextFormField(
                    controller: _desc,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 200,
                    buildCounter: (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                    decoration: const InputDecoration(
                      hintText:
                          'Deskripsi fasilitas dan keunggulan tipe '
                          'kamar...',
                    ),
                    validator: (v) => (v == null || v.trim().length < 10)
                        ? 'Deskripsi minimal 10 karakter'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _ChipEditor(
                    label: 'Fasilitas Kamar',
                    hint: 'Tambah fasilitas...',
                    emptyText: 'Belum ada fasilitas ditambahkan',
                    items: _facilities,
                    onAdd: () => _addChip(_facilities, 'Tambah fasilitas'),
                    onRemove: (v) => setState(() => _facilities.remove(v)),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _ChipEditor(
                    label: 'Paket Bawaan',
                    hint: 'Tambah paket...',
                    emptyText: 'Belum ada paket ditambahkan',
                    items: _packages,
                    error: _submitted && _packages.isEmpty
                        ? 'Tambahkan minimal 1 paket bawaan'
                        : null,
                    onAdd: () => _addChip(_packages, 'Tambah paket bawaan'),
                    onRemove: (v) => setState(() => _packages.remove(v)),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const FieldLabel('Harga per Malam'),
                  TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: '0',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        child: Text(
                          'Rp',
                          style: text.labelLarge!.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(),
                      suffixText: '/ malam',
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '') ?? 0;
                      return n < 10000 ? 'Harga minimal Rp 10.000' : null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const FieldLabel('Jumlah Unit'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _Stepper(
                        value: _units,
                        onChanged: (v) => setState(() => _units = v),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Flexible(
                        child: Text(
                          codes == null
                              ? 'Minimum 1 unit'
                              : 'Kode unit: $codes',
                          textAlign: TextAlign.right,
                          style: text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: FilledButton(onPressed: _save, child: const Text('Simpan Data')),
      ),
    );
  }
}

class _ChipInputDialog extends StatefulWidget {
  const _ChipInputDialog({required this.title});

  final String title;

  @override
  State<_ChipInputDialog> createState() => _ChipInputDialogState();
}

class _ChipInputDialogState extends State<_ChipInputDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: AppColors.muted),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Tambah'),
        ),
      ],
    );
  }
}

class _PhotoBox extends StatelessWidget {
  const _PhotoBox({required this.photo, required this.onTap});

  final String? photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, c) {
          if (photo != null) {
            return Stack(
              children: [
                AppPhoto(
                  photo,
                  size: c.maxWidth,
                  height: 180,
                  placeholderIcon: Icons.bed_outlined,
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FilledButton.tonalIcon(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: const Text('Ubah Foto'),
                  ),
                ),
              ],
            );
          }
          return Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconBubble(icon: Icons.photo_camera_outlined, size: 56),
                SizedBox(height: AppSpacing.sm),
                Text('Tambah foto', style: TextStyle(color: AppColors.primary)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChipEditor extends StatelessWidget {
  const _ChipEditor({
    required this.label,
    required this.hint,
    required this.emptyText,
    required this.items,
    required this.onAdd,
    required this.onRemove,
    this.error,
  });

  final String label;
  final String hint;
  final String emptyText;
  final List<String> items;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(label),
        Material(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.input),
          child: InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(AppRadius.input),
            child: Container(
              height: 56,
              padding: const EdgeInsets.only(left: AppSpacing.lg, right: 6),
              decoration: error == null
                  ? null
                  : BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      border: Border.all(color: AppColors.danger, width: 1.5),
                    ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hint,
                      style: text.bodyLarge!.copyWith(color: AppColors.muted),
                    ),
                  ),
                  FilledButton(
                    onPressed: onAdd,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('+ Tambah'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (error != null)
          Text(error!, style: text.bodySmall!.copyWith(color: AppColors.danger))
        else if (items.isEmpty)
          Text(
            emptyText,
            style: text.bodySmall!.copyWith(fontStyle: FontStyle.italic),
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final item in items)
                InputChip(
                  label: Text(item),
                  onDeleted: () => onRemove(item),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  backgroundColor: AppColors.primarySoft,
                  labelStyle: const TextStyle(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filled(
            tooltip: 'Kurangi',
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.text,
              disabledBackgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton.filled(
            tooltip: 'Tambah',
            onPressed: value < 20 ? () => onChanged(value + 1) : null,
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
