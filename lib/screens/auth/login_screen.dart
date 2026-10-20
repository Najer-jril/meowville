import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_assets.dart';
import '../../widgets/auth_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // void _submit() {
  //   if (!_formKey.currentState!.validate()) return;

  //   final email = _email.text.trim().toLowerCase();
  //   final route = email.contains('admin')
  //       ? AppRoutes.adminHome
  //       : email.contains('sitter')
  //       ? AppRoutes.sitterHome
  //       : AppRoutes.ownerHome;
  //   Navigator.pushReplacementNamed(context, route);
  // }

  void _buttonUts(String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyLarge!.copyWith(color: AppColors.muted);
    final link = text.labelLarge!.copyWith(
      color: AppColors.primary,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primary,
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Text('Masuk', style: AppText.overline),
                  const SizedBox(height: 6),
                  Text(
                    'Selamat datang di Meowville',
                    style: text.headlineLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Masuk untuk memantau kenyamanan dan reservasi anabul tersayang Anda.',
                    style: muted,
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
                        child: _buildCard(text, link),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.center,
                      children: [
                        Text('Belum punya akun Meowville?', style: muted),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.register),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                            ),
                          ),
                          child: Text('Daftar sekarang', style: link),
                        ),
                      ],
                    ),
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

  Widget _buildCard(TextTheme text, TextStyle link) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.soft,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              hint: 'Masukkan kata sandi',
              icon: Icons.lock_outline,
              controller: _password,
              obscure: true,
              textInputAction: TextInputAction.done,
              validator: validateRequired,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: _RememberCheck(
                    value: _remember,
                    onChanged: (v) => setState(() => _remember = v),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.forgotPassword),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                  ),
                  child: Text(
                    'Lupa kata sandi?',
                    style: link.copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => _buttonUts(AppRoutes.adminHome),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Masuk admin',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => _buttonUts(AppRoutes.sitterHome),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Masuk penjaga',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => _buttonUts(AppRoutes.ownerHome),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Masuk owner',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _RememberCheck extends StatelessWidget {
  const _RememberCheck({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(AppRadius.checkbox),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
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
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  'Ingat saya',
                  style: Theme.of(context).textTheme.bodyLarge!
                      .copyWith(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
