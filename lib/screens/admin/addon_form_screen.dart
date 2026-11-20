import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../controllers/addon_controller.dart';
import '../../core/api_client.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class AddonFormScreen extends StatefulWidget {
  const AddonFormScreen({super.key, this.existing});

  final Addon? existing;

  @override
  State<AddonFormScreen> createState() => _AddonFormScreenState();
}

class _AddonFormScreenState extends State<AddonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _desc = TextEditingController(text: widget.existing?.description);
  late final _price = TextEditingController(
    text: widget.existing?.price.toString(),
  );

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _desc.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    super.dispose();
  }

  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<AddonController>().save(
        Addon(
          id: widget.existing?.id ?? 0,
          name: _name.text.trim(),
          description: _desc.text.trim(),
          price: int.parse(_price.text),
          active: widget.existing?.active ?? true,
        ),
        existing: widget.existing,
      );
      if (!mounted) return;
      Navigator.pop(context);
      showSnack(context, _isEdit ? 'Layanan disimpan' : 'Layanan ditambahkan');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: SubPageAppBar(title: _isEdit ? 'Edit Layanan' : 'Tambah Layanan'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          child: Column(
            spacing: AppSpacing.xl,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                spacing: AppSpacing.xs,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    spacing: AppSpacing.sm,
                    children: [
                      const Icon(Icons.spa, color: AppColors.primary, size: 20),
                      Text(
                        'LAYANAN TAMBAHAN',
                        style: text.labelSmall!.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Tambahkan layanan khusus untuk memanjakan anabul selama masa '
                    'penitipan di hotel.',
                    style: text.bodyLarge!.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.page),
                child: Column(
                  spacing: AppSpacing.xl,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LabeledField(
                      label: 'Nama Layanan',
                      child: TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'misal, Grooming Lengkap',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nama layanan wajib diisi'
                            : null,
                      ),
                    ),
                    LabeledField(
                      label: 'Deskripsi',
                      trailing: '${_desc.text.length}/100',
                      child: TextFormField(
                        controller: _desc,
                        minLines: 3,
                        maxLines: 4,
                        maxLength: 100,
                        buildCounter: (
                          _, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                        decoration: const InputDecoration(
                          hintText: 'Jelaskan layanan singkat',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Deskripsi wajib diisi'
                            : null,
                      ),
                    ),
                    LabeledField(
                      label: 'Harga',
                      child: TextFormField(
                        controller: _price,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: '0',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 16, right: 8),
                            child: Text('Rp', style: text.labelLarge),
                          ),
                          prefixIconConstraints: const BoxConstraints(),
                          suffixText: '/ pemesanan',
                          helperText: 'Dikenakan sekali per booking',
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '') ?? 0;
                          return n < 1000 ? 'Harga minimal Rp 1.000' : null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Simpan'),
        ),
      ),
    );
  }
}
