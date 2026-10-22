import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../data/data.dart';
import '../../data/models.dart';
import '../../theme/app_assets.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';

class PetFormScreen extends StatefulWidget {
  const PetFormScreen({super.key, this.existing});

  final Cat? existing;

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  AdminStore get _store => context.read<AdminStore>();
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _breed = TextEditingController(text: widget.existing?.breed);
  late final _weight = TextEditingController(
    text: widget.existing?.weightKg.toString().replaceAll('.', ','),
  );
  late String? _photo = widget.existing?.photo;
  bool _invalid = false;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _weight.dispose();
    super.dispose();
  }

  double? get _weightValue =>
      double.tryParse(_weight.text.trim().replaceAll(',', '.'));

  void _save() {
    final valid = _formKey.currentState!.validate();
    setState(() => _invalid = !valid);
    if (!valid) return;
    final name = _name.text.trim();
    if (_isEdit) {
      _store.updateCat(
        widget.existing!,
        name: name,
        breed: _breed.text.trim(),
        weightKg: _weightValue!,
        photo: _photo,
      );
    } else {
      _store.addCat(
        owner: _store.currentOwner,
        name: name,
        breed: _breed.text.trim(),
        weightKg: _weightValue!,
        photo: _photo,
      );
    }
    Navigator.pop(context);
    showSnack(context, _isEdit ? 'Perubahan disimpan' : '$name ditambahkan');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SubPageAppBar(title: _isEdit ? 'Edit Kucing' : 'Tambah Kucing'),
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
            if (_invalid) ...[
              const NoticeBox.danger(
                title: 'Ada data yang belum lengkap',
                message: 'Periksa kolom bertanda merah di bawah.',
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: _PhotoPicker(
                      photo: _photo,
                      onTap: () => setState(() => _photo = AppImages.catDialga),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const FieldLabel('Nama kucing', required: true),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'misal, Luna'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const FieldLabel('Ras', required: true),
                  TextFormField(
                    controller: _breed,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'misal, Domestic (opsional)',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const FieldLabel('Berat', required: true),
                  TextFormField(
                    controller: _weight,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(
                      hintText: 'misal, 3,8',
                      suffixText: 'kg',
                    ),
                    validator: (_) {
                      final w = _weightValue;
                      if (_weight.text.trim().isEmpty) return 'Wajib diisi';
                      if (w == null || w <= 0 || w > 20) {
                        return 'berat antara 0,1 sampai 20 kg';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: FilledButton(
          onPressed: _save,
          child: Text(_isEdit ? 'Simpan Perubahan' : 'Simpan'),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.photo, required this.onTap});

  final String? photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              photo == null
                  ? Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    )
                  : AppPhoto(photo, size: 120),
              if (photo != null)
                const Positioned(
                  right: -6,
                  bottom: -6,
                  child: IconBubble(
                    icon: Icons.photo_camera_outlined,
                    color: Colors.white,
                    background: AppColors.primary,
                    size: 40,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            photo == null ? 'Tambah foto (opsional)' : 'Ketuk untuk mengganti',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
