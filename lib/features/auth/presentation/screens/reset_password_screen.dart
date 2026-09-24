import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/auth_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/app_helper_note.dart';
import '../../../../core/widgets/app_inline_link.dart';
import '../../../../core/widgets/app_password_field.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/recovery_code.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/confirm_password_reset_usecase.dart';
import '../../domain/usecases/request_password_reset_usecase.dart';
import '../providers/form_submission_status.dart';
import '../providers/reset_password_controller.dart';
import '../widgets/auth_footer_prompt.dart';
import '../widgets/auth_layout.dart';
import '../widgets/form_error_banner.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ResetPasswordController>(
      create: (BuildContext context) {
        final AuthRepository repository = context.read<AuthRepository>();
        return ResetPasswordController(
          ConfirmPasswordResetUseCase(repository),
          RequestPasswordResetUseCase(repository),
          initialEmail: initialEmail,
        );
      },
      child: const _ResetPasswordView(),
    );
  }
}

class _ResetPasswordView extends StatefulWidget {
  const _ResetPasswordView();

  @override
  State<_ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<_ResetPasswordView> {
  final FocusNode _codeFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  @override
  void dispose() {
    _codeFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ResetPasswordController controller = context
        .read<ResetPasswordController>();
    if (!controller.canSubmit) {
      return;
    }
    FocusScope.of(context).unfocus();

    final bool changed = await controller.submit();
    if (!mounted || !changed) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kata sandi diperbarui. Anda sudah masuk.'),
        duration: Duration(seconds: 5),
      ),
    );
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final ResetPasswordController controller = context
        .watch<ResetPasswordController>();
    final bool isSubmitting = controller.status.isSubmitting;

    return AuthLayout(
      eyebrow: 'Pemulihan akun',
      title: 'Buat Kata Sandi Baru',
      subtitle:
          'Masukkan kode enam angka dari email, lalu pilih kata sandi '
          'baru.',
      panelStatement: 'Satu kode dari email, satu kata sandi baru.',
      form: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (controller.notice != null) ...<Widget>[
              Semantics(
                liveRegion: true,
                container: true,
                child: AppHelperNote(
                  text: controller.notice!,
                  icon: Icons.mark_email_unread_outlined,
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
            ],
            if (controller.hasFixedEmail) ...<Widget>[
              const AppFieldLabel(text: 'Kode dikirim ke'),
              const SizedBox(height: AppSpacing.space4),
              Text(
                controller.emailController.text,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ] else ...<Widget>[
              const AppFieldLabel(text: 'Alamat Email'),
              const SizedBox(height: AppSpacing.space8),
              AppTextField(
                controller: controller.emailController,
                hintText: 'nama@email.com',
                semanticLabel: 'Alamat email',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const <String>[AutofillHints.email],
                enabled: !isSubmitting,
                errorText: controller.emailError,
                onChanged: (_) => controller.clearErrors(),
                onSubmitted: (_) => _codeFocusNode.requestFocus(),
              ),
            ],
            const SizedBox(height: AppSpacing.space20),
            const AppFieldLabel(text: 'Kode Enam Angka'),
            const SizedBox(height: AppSpacing.space8),
            AppTextField(
              controller: controller.codeController,
              focusNode: _codeFocusNode,
              hintText: 'Masukkan 6 angka dari email',
              semanticLabel: 'Kode enam angka',
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(RecoveryCode.length),
              ],
              autofillHints: const <String>[AutofillHints.oneTimeCode],
              enabled: !isSubmitting,
              errorText: controller.codeError,
              onChanged: (_) => controller.clearErrors(),
              onSubmitted: (_) => _passwordFocusNode.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.space20),
            const AppFieldLabel(text: 'Kata Sandi Baru'),
            const SizedBox(height: AppSpacing.space8),
            AppPasswordField(
              controller: controller.passwordController,
              focusNode: _passwordFocusNode,
              hintText: 'Minimal 8 karakter',
              semanticLabel: 'Kata sandi baru',
              obscured: controller.obscurePassword,
              onToggleObscured: controller.toggleObscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.newPassword],
              enabled: !isSubmitting,
              errorText: controller.passwordError,
              onChanged: (_) => controller.clearErrors(),
              onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.space20),
            const AppFieldLabel(text: 'Konfirmasi Kata Sandi Baru'),
            const SizedBox(height: AppSpacing.space8),
            AppPasswordField(
              controller: controller.confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              hintText: 'Ulangi kata sandi baru',
              semanticLabel: 'Konfirmasi kata sandi baru',
              obscured: controller.obscureConfirmPassword,
              onToggleObscured: controller.toggleObscureConfirmPassword,
              autofillHints: const <String>[AutofillHints.newPassword],
              enabled: !isSubmitting,
              errorText: controller.confirmPasswordError,
              onChanged: (_) => controller.clearErrors(),
              onSubmitted: (_) => _submit(),
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
              label: 'Simpan Kata Sandi Baru',
              isLoading: isSubmitting,
              onPressed: controller.canSubmit || isSubmitting ? _submit : null,
            ),
            const SizedBox(height: AppSpacing.space8),
            Center(child: _ResendControl(controller: controller)),
          ],
        ),
      ),
      footer: Column(
        children: <Widget>[
          if (controller.hasFixedEmail) ...<Widget>[
            AuthFooterPrompt(
              question: 'Salah alamat email?',
              actionLabel: 'Ubah Email',
              onAction: () =>
                  context.pushReplacement(AuthRoutes.forgotPassword),
            ),
            const SizedBox(height: AppSpacing.space8),
          ],
          AuthFooterPrompt(
            question: 'Sudah ingat kata sandinya?',
            actionLabel: 'Kembali Masuk',
            onAction: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}

class _ResendControl extends StatelessWidget {
  const _ResendControl({required this.controller});

  final ResetPasswordController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.canResend) {
      return AppInlineLink(text: 'Kirim ulang kode', onTap: controller.resend);
    }

    final String text = controller.isResending
        ? 'Mengirim ulang kode...'
        : 'Kirim ulang kode dalam ${controller.resendSecondsLeft} detik';
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.minTapTarget),
      child: Center(
        widthFactor: 1,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTypography.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
