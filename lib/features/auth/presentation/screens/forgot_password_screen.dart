import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/auth_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/request_password_reset_usecase.dart';
import '../providers/forgot_password_controller.dart';
import '../providers/form_submission_status.dart';
import '../widgets/auth_footer_prompt.dart';
import '../widgets/auth_layout.dart';
import '../widgets/form_error_banner.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ForgotPasswordController>(
      create: (BuildContext context) => ForgotPasswordController(
        RequestPasswordResetUseCase(context.read<AuthRepository>()),
      ),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatelessWidget {
  const _ForgotPasswordView();

  Future<void> _submit(BuildContext context) async {
    final ForgotPasswordController controller = context
        .read<ForgotPasswordController>();
    FocusScope.of(context).unfocus();

    final bool sent = await controller.submit();
    if (!context.mounted || !sent) {
      return;
    }
    context.go(AuthRoutes.resetPassword, extra: controller.submittedEmail);
  }

  @override
  Widget build(BuildContext context) {
    final ForgotPasswordController controller = context
        .watch<ForgotPasswordController>();
    final bool isSubmitting = controller.status.isSubmitting;

    return AuthLayout(
      eyebrow: 'Pemulihan akun',
      title: 'Lupa Kata Sandi',
      subtitle:
          'Masukkan email akun Anda. Kami kirim kode enam angka untuk '
          'membuat kata sandi baru.',
      panelStatement:
          'Akun Anda bisa dibuka kembali lewat email yang terdaftar.',
      form: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const AppFieldLabel(text: 'Alamat Email'),
            const SizedBox(height: AppSpacing.space8),
            AppTextField(
              controller: controller.emailController,
              hintText: 'nama@email.com',
              semanticLabel: 'Alamat email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[AutofillHints.email],
              enabled: !isSubmitting,
              errorText: controller.emailError,
              onChanged: (_) => controller.clearErrors(),
              onSubmitted: (_) => _submit(context),
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
              label: 'Kirim Kode ke Email',
              isLoading: isSubmitting,
              onPressed: () => _submit(context),
            ),
          ],
        ),
      ),
      footer: AuthFooterPrompt(
        question: 'Sudah ingat kata sandinya?',
        actionLabel: 'Kembali Masuk',
        onAction: () => context.go('/login'),
      ),
    );
  }
}
