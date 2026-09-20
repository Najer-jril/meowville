import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/legal_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/auth_notifier.dart';
import '../providers/register_sitter_controller.dart';
import '../widgets/auth_footer_prompt.dart';
import '../widgets/auth_layout.dart';
import '../widgets/register_account_form.dart';

class RegisterSitterScreen extends StatefulWidget {
  const RegisterSitterScreen({super.key});

  @override
  State<RegisterSitterScreen> createState() => _RegisterSitterScreenState();
}

class _RegisterSitterScreenState extends State<RegisterSitterScreen> {
  Future<void> _submit() async {
    final RegisterSitterController controller = context
        .read<RegisterSitterController>();
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
          'Akun penjaga dibuat. Buka tautan verifikasi di email Anda, '
          'lalu masuk.',
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
    final RegisterSitterController controller = context
        .watch<RegisterSitterController>();

    return AuthLayout(
      eyebrow: 'Akun penjaga baru',
      title: 'Daftar Jadi Penjaga',
      subtitle:
          'Buat akun penjaga untuk menerima jadwal titipan dan mengirim '
          'kabar harian ke pemilik.',
      panelStatement: 'Tangan yang telaten menjaga kamar tetap hangat.',
      form: RegisterAccountForm(
        controller: controller,
        identityStepLabel: 'Data penjaga',
        submitLabel: 'Buat Akun Penjaga',
        onSubmitted: _submit,
        onOpenTerms: _openTerms,
        onOpenPrivacy: _openPrivacy,
      ),
      footer: Column(
        children: <Widget>[
          AuthFooterPrompt(
            question: 'Sudah memiliki akun?',
            actionLabel: 'Masuk di sini',
            onAction: () => context.go('/login'),
          ),
          const SizedBox(height: AppSpacing.space8),
          AuthFooterPrompt(
            question: 'Menitipkan kucing, bukan menjaga?',
            actionLabel: 'Daftar akun pemilik',
            onAction: () => context.go('/register'),
          ),
        ],
      ),
    );
  }
}
