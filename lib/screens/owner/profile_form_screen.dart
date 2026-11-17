import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/api_client.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/common.dart';
import '../../widgets/photo_picker.dart';

class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.name);
  late final _phone = TextEditingController(text: widget.user.phone);
  late String? _photo = widget.user.photo;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final path = await pickPhoto(context);
    if (path != null && mounted) setState(() => _photo = path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<AuthController>().updateProfile(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        photo: _photo,
      );
      if (!mounted) return;
      Navigator.pop(context);
      showSnack(context, 'Profil disimpan');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SubPageAppBar(title: 'Edit Profil'),
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
                spacing: AppSpacing.lg,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _saving ? null : _pickPhoto,
                      child: Column(
                        spacing: AppSpacing.sm,
                        children: [
                          UserAvatar(
                            initial: widget.user.initial,
                            photo: _photo,
                            size: 96,
                          ),
                          Text(
                            'Ketuk untuk mengganti foto',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AuthTextField(
                    label: 'Nama lengkap',
                    hint: 'misal, Najer Pinkman',
                    icon: Icons.person_outline,
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    validator: validateRequired,
                  ),
                  AuthTextField(
                    label: 'Nomor WhatsApp',
                    hint: 'misal, 0812-3456-7890',
                    icon: Icons.call_outlined,
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                      if (digits.isEmpty) return 'Wajib diisi';
                      if (digits.length < 10) return 'Nomor minimal 10 digit';
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
          onPressed: _saving ? null : _save,
          child: const Text('Simpan'),
        ),
      ),
    );
  }
}
