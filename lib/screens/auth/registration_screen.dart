import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/gestures.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_assets.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/auth_header.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
  }

  late final _legalTap = TapGestureRecognizer()
    ..onTap = () => Navigator.pushNamed(context, AppRoutes.legal);
  late final _policyTap = TapGestureRecognizer()
    ..onTap = () => Navigator.pushNamed(context, AppRoutes.policy);

  @override
  void dispose() {
    _legalTap.dispose();
    _policyTap.dispose();
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _backToLogin() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed(AppRoutes.login);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    messenger.showSnackBar(
      const SnackBar(content: Text('Akun berhasil dibuat. Silakan masuk.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyLarge!.copyWith(color: AppColors.muted);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthHeader(showTitle: true, onBack: _backToLogin),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Akun pemilik baru', style: AppText.overline),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Daftar akun Meowville', style: text.headlineLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Bergabunglah dengan Meowville untuk memesan kamar & memantau anabul Anda.',
                        style: muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Stack(
                    children: [
                      Opacity(
                        opacity: 0.6,
                        child: SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: SvgPicture.asset(
                            AppSvg.catHouse,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: _buildCard(text),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _FooterLink(
                    prompt: 'Sudah memiliki akun?',
                    action: 'Masuk di sini',
                    onTap: _backToLogin,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(TextTheme text) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.soft,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionHeader(number: '01', title: 'Data pemilik'),
              const SizedBox(height: AppSpacing.lg),
              AuthTextField(
                label: 'Nama lengkap',
                hint: 'cth. Nama sesuai KTP',
                icon: Icons.person_outline,
                controller: _name,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                validator: validateRequired,
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthTextField(
                label: 'Nomor WhatsApp',
                hint: 'cth. 0812-3456-7890',
                icon: Icons.chat_bubble_outline,
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: validateRequired,
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionHeader(number: '02', title: 'Akses akun'),
              const SizedBox(height: AppSpacing.lg),
              AuthTextField(
                label: 'Alamat email',
                hint: 'nama@email.com',
                icon: Icons.mail_outline,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: validateEmail,
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthTextField(
                label: 'Kata sandi',
                hint: 'Minimal 8 karakter',
                icon: Icons.lock_outline,
                controller: _password,
                obscure: true,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    validateRequired(v) ??
                    (v!.length < 8 ? 'Minimal 8 karakter' : null),
              ),
              if (_password.text.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _StrengthMeter(password: _password.text),
              ],
              const SizedBox(height: AppSpacing.lg),
              AuthTextField(
                label: 'Konfirmasi kata sandi',
                hint: 'Ulangi kata sandi',
                icon: Icons.lock_outline,
                controller: _confirm,
                obscure: true,
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    validateRequired(v) ??
                    (v != _password.text ? 'Kata sandi tidak sama' : null),
              ),
              const SizedBox(height: AppSpacing.xl),
              _AgreementCheck(
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v),
                legalTap: _legalTap,
                policyTap: _policyTap,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _agreed ? _submit : null,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'Buat akun Meowville',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.number, required this.title});

  final String number;
  final String title;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge!;
    return Row(
      children: [
        Text(number, style: style.copyWith(color: AppColors.primary)),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: style),
        const SizedBox(width: AppSpacing.md),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.password});

  final String password;

  int get _score => [
    password.length >= 8,
    password.contains(RegExp(r'[A-Z]')),
    password.contains(RegExp(r'[0-9]')),
    password.contains(RegExp(r'[^A-Za-z0-9]')),
  ].where((ok) => ok).length;

  @override
  Widget build(BuildContext context) {
    final score = _score;
    final (label, color) = switch (score) {
      4 => ('Kuat', AppColors.success),
      3 => ('Sedang', AppColors.warning),
      _ => ('Lemah', AppColors.danger),
    };
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 6,
              decoration: BoxDecoration(
                color: i < score ? color : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
        ],
        const SizedBox(width: AppSpacing.md),
        Text(
          'Kekuatan: $label',
          style: Theme.of(context).textTheme.bodySmall!
              .copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _AgreementCheck extends StatelessWidget {
  const _AgreementCheck({
    required this.value,
    required this.onChanged,
    required this.legalTap,
    required this.policyTap,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final GestureRecognizer legalTap;
  final GestureRecognizer policyTap;

  @override
  Widget build(BuildContext context) {
    final caption = Theme.of(context).textTheme.bodySmall!;
    final link = caption.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primary,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          checked: value,
          label: 'Setujui ketentuan',
          child: InkWell(
            onTap: () => onChanged(!value),
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: value ? AppColors.primary : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadius.checkbox),
                  ),
                  child: value
                      ? const Icon(
                          Icons.check,
                          size: 18,
                          color: AppColors.surface,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text.rich(
              TextSpan(
                style: caption,
                children: [
                  const TextSpan(text: 'Saya menyetujui '),
                  TextSpan(
                    text: 'Ketentuan Layanan Penitipan',
                    style: link,
                    recognizer: legalTap,
                  ),
                  const TextSpan(text: ' & '),
                  TextSpan(
                    text: 'Kebijakan Meowville',
                    style: link,
                    recognizer: policyTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt, style: text.bodyLarge!.copyWith(color: AppColors.muted)),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          ),
          child: Text(
            action,
            style: text.labelLarge!.copyWith(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
