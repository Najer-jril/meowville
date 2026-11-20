import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/api_client.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_assets.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/common.dart';

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
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await context.read<AuthController>().signIn(
        _email.text.trim(),
        _password.text,
        remember: _remember,
      );
      if (mounted) AppRoutes.enterHome(context, user);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } on Object {
      if (mounted) showSnack(context, 'Tidak dapat terhubung ke server');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.page,
            vertical: AppSpacing.lg,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                spacing: AppSpacing.lg,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    spacing: AppSpacing.sm,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat datang di Meowville',
                        style: text.headlineLarge,
                      ),
                      Text(
                        'Masuk ke akun anda jika sudah memiliki akun, atau '
                        'daftar jika belum memiliki akun',
                        style: muted,
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      Opacity(
                        opacity: 0.6,
                        child: SvgPicture.asset(
                          AppSvg.catHouse,
                          width: double.infinity,
                          height: AppSizes.artSm,
                          fit: BoxFit.fill,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: _buildCard(text, link),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.center,
                        children: [
                          Text('Belum punya akun Meowville?', style: muted),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.register,
                            ),
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
                  ),
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
          spacing: AppSpacing.lg,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              label: 'email',
              hint: 'nama@email.com',
              icon: Icons.mail_outline,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: validateEmail,
            ),
            AuthTextField(
              label: 'Password',
              hint: 'Masukkan password',
              icon: Icons.lock_outline,
              controller: _password,
              obscure: true,
              textInputAction: TextInputAction.done,
              validator: validateRequired,
              onFieldSubmitted: (_) => _submit(),
            ),
            Row(
              spacing: AppSpacing.sm,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: _RememberCheck(
                    value: _remember,
                    onChanged: (v) => setState(() => _remember = v),
                  ),
                ),
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
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? ConstrainedBox(
                        constraints: const BoxConstraints.tightFor(
                          width: AppSizes.spinner,
                          height: AppSizes.spinner,
                        ),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.surface,
                        ),
                      )
                    : const Text('Masuk'),
              ),
            ),
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
            spacing: AppSpacing.sm,
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
