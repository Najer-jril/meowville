import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../data/data.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/common.dart';

class UserCreateScreen extends StatefulWidget {
  const UserCreateScreen({super.key});

  @override
  State<UserCreateScreen> createState() => _UserCreateScreenState();
}

class _UserCreateScreenState extends State<UserCreateScreen> {
  static const _roles = <(UserRole, String, String)>[
    (UserRole.owner, 'Pemilik', 'Memesan kamar dan memantau kucing'),
    (
      UserRole.admin,
      'Admin',
      'Mengelola reservasi, kamar, layanan, dan akun. Termasuk akses Pet '
          'Sitter',
    ),
    (UserRole.sitter, 'Pet Sitter', 'Check-in/out dan laporan kondisi harian'),
  ];

  AdminStore get _store => context.read<AdminStore>();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  UserRole? _role;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _phone, _email, _password]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _filled =>
      _name.text.trim().isNotEmpty &&
      _phone.text.trim().isNotEmpty &&
      _email.text.trim().isNotEmpty &&
      _password.text.isNotEmpty &&
      _role != null;

  void _submit() {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate() || _role == null) return;
    _store.addUser(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      role: _role!,
    );
    Navigator.pop(context);
    showSnack(context, 'Akun ${_name.text.trim()} berhasil dibuat');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const SubPageAppBar(title: 'Buat Akun'),
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
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pets, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Pendaftaran akun baru',
                      style: text.labelLarge!.copyWith(
                        fontSize: 14,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    label: 'Nama lengkap',
                    hint: 'misal, Mahar Uzumaki',
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
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                      if (digits.isEmpty) return 'Wajib diisi';
                      if (digits.length < 10) return 'Nomor minimal 10 digit';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AuthTextField(
                    label: 'Alamat email',
                    hint: 'nama@email.com',
                    icon: Icons.mail_outline,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final e = validateEmail(v);
                      if (e != null) return e;
                      return _store.emailTaken(v!.trim())
                          ? 'Email sudah terdaftar'
                          : null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AuthTextField(
                    label: 'Kata sandi sementara',
                    hint: 'Minimal 8 karakter',
                    icon: Icons.lock_outline,
                    controller: _password,
                    obscure: true,
                    helperText:
                        'Sampaikan kata sandi ini langsung kepada '
                        'pengguna',
                    validator: (v) => (v == null || v.length < 8)
                        ? 'Kata sandi minimal 8 karakter'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Peran', style: text.labelLarge!.copyWith(fontSize: 14)),
                  const SizedBox(height: AppSpacing.sm),
                  RadioGroup<UserRole>(
                    groupValue: _role,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _role = v);
                    },
                    child: Column(
                      children: [
                        for (final r in _roles)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _RoleTile(
                              value: r.$1,
                              title: r.$2,
                              subtitle: r.$3,
                              selected: _role == r.$1,
                              onTap: () => setState(() => _role = r.$1),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_submitted && _role == null)
                    Text(
                      'Pilih peran akun',
                      style: text.bodySmall!.copyWith(color: AppColors.danger),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: FilledButton(
          onPressed: _filled ? _submit : null,
          child: const Text('Buat Akun'),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final UserRole value;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: selected ? const Color(0xFFF2FBFA) : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Radio<UserRole>(value: value),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    right: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.bodyLarge),
                      Text(
                        subtitle,
                        style: text.bodySmall!.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
