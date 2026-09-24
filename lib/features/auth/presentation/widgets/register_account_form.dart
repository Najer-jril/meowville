import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/app_password_field.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/form_submission_status.dart';
import '../providers/register_controller.dart';
import 'form_error_banner.dart';
import 'terms_consent_row.dart';

class RegisterAccountForm extends StatefulWidget {
  const RegisterAccountForm({
    super.key,
    required this.controller,
    required this.identityStepLabel,
    required this.submitLabel,
    required this.onSubmitted,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
  });

  final RegisterController controller;
  final String identityStepLabel;
  final String submitLabel;
  final Future<void> Function() onSubmitted;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;

  @override
  State<RegisterAccountForm> createState() => _RegisterAccountFormState();
}

class _RegisterAccountFormState extends State<RegisterAccountForm> {
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

  @override
  Widget build(BuildContext context) {
    final RegisterController controller = widget.controller;
    final bool isSubmitting = controller.status.isSubmitting;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _FormStep(number: '01', label: widget.identityStepLabel),
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
            onSubmitted: (_) => widget.onSubmitted(),
          ),
          const SizedBox(height: AppSpacing.space20),
          TermsConsentRow(
            accepted: controller.termsAccepted,
            onChanged: controller.setTermsAccepted,
            onOpenTerms: widget.onOpenTerms,
            onOpenPrivacy: widget.onOpenPrivacy,
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
            label: widget.submitLabel,
            isLoading: isSubmitting,
            onPressed: widget.onSubmitted,
          ),
        ],
      ),
    );
  }
}

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
