import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/data.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/common.dart';

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

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AdminStore>().updateProfile(
      widget.user,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
    );
    Navigator.pop(context);
    showSnack(context, 'Profil disimpan');
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    label: 'Nama lengkap',
                    hint: 'misal, Najer Pinkman',
                    icon: Icons.person_outline,
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    validator: validateRequired,
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
        child: FilledButton(onPressed: _save, child: const Text('Simpan')),
      ),
    );
  }
}
