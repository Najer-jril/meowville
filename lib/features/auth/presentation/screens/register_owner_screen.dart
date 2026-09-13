import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/legal_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/app_password_field.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_notifier.dart';
import '../providers/form_submission_status.dart';
import '../providers/register_controller.dart';
import '../widgets/auth_footer_prompt.dart';
import '../widgets/auth_layout.dart';
import '../widgets/form_error_banner.dart';
import '../widgets/terms_consent_row.dart';

class RegisterOwnerScreen extends StatefulWidget {
  const RegisterOwnerScreen({super.key});

  @override
  State<RegisterOwnerScreen> createState() => _RegisterOwnerScreenState();
}

class _RegisterOwnerScreenState extends State<RegisterOwnerScreen> {
  final FocusNode _whatsappFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  @override
  void dispose() {
    _whatsappFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final RegisterController controller = context.read<RegisterController>();
    FocusScope.of(context).unfocus();

    final bool registered = await controller.submit();
    if (!mounted || !registered) {
      return;
    }

    final bool signedIn = context.read<AuthNotifier>().isAuthenticated;
    if (signedIn) {
      context.go('/');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Akun dibuat. Buka tautan verifikasi di email Anda, lalu masuk.',
        ),
        duration: Duration(seconds: 6),
      ),
    );
    context.go('/login');
  }

  void _openTerms() => context.push(LegalRoutes.ketentuanLayanan);

  void _openPrivacy() => context.push(LegalRoutes.kebijakanPrivasi);

  @override
  Widget build(BuildContext context) {
    final RegisterController controller = context.watch<RegisterController>();
    final bool isSubmitting = controller.status.isSubmitting;

    return AuthLayout(
      eyebrow: 'Akun pemilik baru',
      title: 'Daftar Akun Meowville',
      subtitle:
          'Bergabunglah dengan Meowville untuk memesan kamar & '
          'memantau anabul Anda.',
      panelStatement: 'Satu akun untuk semua kunjungan anabul Anda.',
      form: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _FormStep(number: '01', label: 'Data pemilik'),
            const SizedBox(height: AppSpacing.space16),
            const AppFieldLabel(text: 'Nama Lengkap'),
            const SizedBox(height: AppSpacing.space8),
            AppTextField(
              controller: controller.nameController,
              hintText: 'cth. Nama sesuai KTP',
              semanticLabel: 'Nama lengkap',
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              autofillHints: const <String>[AutofillHints.name],
              enabled: !isSubmitting,
              errorText: controller.nameError,
              onChanged: (_) => controller.clearErrors(),
              onSubmitted: (_) => _whatsappFocusNode.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.space16),
            const AppFieldLabel(text: 'Nomor WhatsApp'),
            const SizedBox(height: AppSpacing.space8),
            AppTextField(
              controller: controller.whatsappController,
              focusNode: _whatsappFocusNode,
              hintText: 'cth. 0812-3456-7890',
              semanticLabel: 'Nomor WhatsApp',
              keyboardType: TextInputType.phone,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ \-]')),
                LengthLimitingTextInputFormatter(20),
              ],
              autofillHints: const <String>[AutofillHints.telephoneNumber],
              enabled: !isSubmitting,
              errorText: controller.whatsappError,
              onChanged: (_) => controller.clearErrors(),
              onSubmitted: (_) => _emailFocusNode.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.space32),
            const _FormStep(number: '02', label: 'Akses akun'),
            const SizedBox(height: AppSpacing.space16),
            const AppFieldLabel(text: 'Alamat Email'),
            const SizedBox(height: AppSpacing.space8),
            AppTextField(
              controller: controller.emailController,
              focusNode: _emailFocusNode,
              hintText: 'nama@email.com',
              semanticLabel: 'Alamat email',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const <String>[AutofillHints.email],
              enabled: !isSubmitting,
              errorText: controller.emailError,
              onChanged: (_) => controller.clearErrors(),
              onSubmitted: (_) => _passwordFocusNode.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.space16),
            const AppFieldLabel(text: 'Kata Sandi'),
            const SizedBox(height: AppSpacing.space8),
            AppPasswordField(
              controller: controller.passwordController,
              focusNode: _passwordFocusNode,
              hintText: 'Minimal 8 karakter',
              semanticLabel: 'Kata sandi',
              obscured: controller.obscurePassword,
              onToggleObscured: controller.toggleObscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.newPassword],
              enabled: !isSubmitting,
              errorText: controller.passwordError,
              onChanged: (_) => controller.clearErrors(),
              onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.space16),
            const AppFieldLabel(text: 'Konfirmasi Kata Sandi'),
            const SizedBox(height: AppSpacing.space8),
            AppPasswordField(
              controller: controller.confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              hintText: 'Ulangi kata sandi',
              semanticLabel: 'Konfirmasi kata sandi',
              obscured: controller.obscureConfirmPassword,
              onToggleObscured: controller.toggleObscureConfirmPassword,
              enabled: !isSubmitting,
              errorText: controller.confirmPasswordError,
              onChanged: (_) => controller.clearErrors(),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.space20),
            TermsConsentRow(
              accepted: controller.termsAccepted,
              onChanged: controller.setTermsAccepted,
              onOpenTerms: _openTerms,
              onOpenPrivacy: _openPrivacy,
              enabled: !isSubmitting,
              errorText: controller.termsError,
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
              label: 'Buat Akun Meowville',
              isLoading: isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
      footer: AuthFooterPrompt(
        question: 'Sudah memiliki akun?',
        actionLabel: 'Masuk di sini',
        onAction: () => context.go('/login'),
      ),
    );
  }
}

/// Penanda kelompok isian: nomor terracotta, label, lalu garis tulang.
class _FormStep extends StatelessWidget {
  const _FormStep({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: label,
      excludeSemantics: true,
      child: Row(
        children: <Widget>[
          Text(
            number,
            style: AppTypography.tabularNumeric.copyWith(
              color: AppColors.brandTerracottaDark,
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
          Text(label, style: AppTypography.labelLg),
          const SizedBox(width: AppSpacing.space12),
          const Expanded(child: Divider(color: AppColors.outlineVariant)),
        ],
      ),
    );
  }
}
