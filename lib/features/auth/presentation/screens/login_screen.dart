import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/app_password_field.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/pending_feature_sheet.dart';
import '../providers/form_submission_status.dart';
import '../providers/login_controller.dart';
import '../widgets/auth_footer_prompt.dart';
import '../widgets/auth_layout.dart';
import '../widgets/form_error_banner.dart';
import '../widgets/remember_forgot_row.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final LoginController controller = context.read<LoginController>();
    FocusScope.of(context).unfocus();

    final bool signedIn = await controller.submit();
    if (!mounted || !signedIn) {
      return;
    }
    context.go('/');
  }

  Future<void> _openForgotPassword() {
    return showPendingFeatureSheet(
      context,
      title: 'Pemulihan kata sandi belum tersedia',
      description:
          'Reset mandiri belum aktif. Hubungi admin Meowville untuk '
          'membuka kembali akun Anda.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final LoginController controller = context.watch<LoginController>();
    final bool isSubmitting = controller.status.isSubmitting;

    return AuthLayout(
      eyebrow: 'Masuk',
      title: 'Selamat Datang di Meowville',
      subtitle:
          'Masuk untuk memantau kenyamanan dan reservasi '
          'anabul tersayang Anda.',
      panelStatement: 'Kamar hangat, kabar harian, dan tangan yang telaten.',
      form: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const AppFieldLabel(text: 'Alamat Email'),
            const SizedBox(height: AppSpacing.space8),
            AppTextField(
              controller: controller.identifierController,
              hintText: 'nama@email.com',
              semanticLabel: 'Alamat email',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const <String>[AutofillHints.username],
              enabled: !isSubmitting,
              errorText: controller.identifierError,
              onChanged: (_) => controller.clearErrors(),
              onSubmitted: (_) => _passwordFocusNode.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.space20),
            const AppFieldLabel(text: 'Kata Sandi'),
            const SizedBox(height: AppSpacing.space8),
            AppPasswordField(
              controller: controller.passwordController,
              focusNode: _passwordFocusNode,
              hintText: 'Masukkan kata sandi',
              semanticLabel: 'Kata sandi',
              obscured: controller.obscurePassword,
              onToggleObscured: controller.toggleObscurePassword,
              autofillHints: const <String>[AutofillHints.password],
              enabled: !isSubmitting,
              errorText: controller.passwordError,
              onChanged: (_) => controller.clearErrors(),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.space12),
            RememberForgotRow(
              rememberMe: controller.rememberMe,
              onRememberChanged: controller.setRememberMe,
              onForgotPassword: _openForgotPassword,
              enabled: !isSubmitting,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: controller.errorMessage == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.space12),
                      child: FormErrorBanner(message: controller.errorMessage!),
                    ),
            ),
            const SizedBox(height: AppSpacing.space20),
            AppPrimaryButton(
              label: 'Masuk ke Akun',
              isLoading: isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
      footer: AuthFooterPrompt(
        question: 'Belum punya akun Meowville?',
        actionLabel: 'Daftar Sekarang',
        onAction: () => context.go('/register'),
      ),
    );
  }
}
