import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/api_client.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_assets.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/common.dart';
import '../../widgets/support_contact.dart';

const _resendSeconds = 60;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _resetKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _sent = false;
  bool _busy = false;
  int _secondsLeft = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) timer.cancel();
      setState(() => _secondsLeft--);
    });
  }

  Future<bool> _requestCode() async {
    setState(() => _busy = true);
    try {
      await context.read<AuthController>().sendResetCode(_email.text.trim());
      return true;
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    if (!await _requestCode() || !mounted) return;
    setState(() => _sent = true);
    _startCountdown();
  }

  Future<void> _resend() async {
    if (await _requestCode() && mounted) {
      showSnack(context, 'Kode baru terkirim');
      _startCountdown();
    }
  }

  Future<void> _reset() async {
    if (!_resetKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await context.read<AuthController>().resetPassword(
        _email.text.trim(),
        _code.text.trim(),
        _password.text,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Password diperbarui. Silakan masuk.')),
      );
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toLogin() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          ...(_sent ? _successDecor() : _formDecor()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    children: [
                      AuthHeader(showTitle: !_sent, onBack: _toLogin),
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _sent ? _buildSuccess() : _buildForm(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _formDecor() => [
    _Decor(
      top: -48,
      right: -32,
      angle: 12,
      opacity: 0.4,
      child: SvgPicture.asset(AppSvg.pawBig, width: 176, height: 176),
    ),
    _Decor(
      top: 320,
      left: -40,
      angle: -45,
      opacity: 0.3,
      child: SvgPicture.asset(AppSvg.pawSmall, width: 144, height: 144),
    ),
  ];

  List<Widget> _successDecor() => [
    _Decor(
      top: -24,
      right: -24,
      child: _Blob(color: AppColors.secondarySoft.withValues(alpha: 0.4)),
    ),
    _Decor(
      top: MediaQuery.sizeOf(context).height / 3,
      left: -40,
      child: _Blob(color: AppColors.primarySoft.withValues(alpha: 0.3)),
    ),
    _Decor(
      top: 80,
      right: 32,
      angle: 12,
      opacity: 0.7,
      child: SvgPicture.asset(AppSvg.pawSmall, width: 34, height: 34),
    ),
    _Decor(
      bottom: 112,
      left: AppSpacing.lg,
      angle: -12,
      opacity: 0.6,
      child: SvgPicture.asset(AppSvg.pawSmall, width: 28, height: 28),
    ),
  ];

  Widget _buildForm() {
    final text = Theme.of(context).textTheme;
    return Column(
      key: const ValueKey('form'),
      children: [
        Column(
          spacing: AppSpacing.sm,
          children: [
            _Illustration(
              asset: AppSvg.envelopeCat,
              size: 176,
              glow: AppColors.primarySoft,
            ),
            const _Heading(
              overline: 'Lupa kata sandi',
              title: 'Aman, kami bantu',
              body:
                  'Masukkan email akun Anda. Kami akan mengirim kode 6 digit '
                  'untuk mengatur ulang kata sandi.',
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.page,
            bottom: AppSpacing.lg,
          ),
          child: Transform.translate(
            offset: const Offset(0, -12),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: AppShadows.soft,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  spacing: AppSpacing.page,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthTextField(
                      label: 'Alamat email',
                      hint: 'nama@email.com',
                      icon: Icons.mail_outline,
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      helperText:
                          'Gunakan email yang terdaftar saat membuat profil.',
                      validator: validateEmail,
                    ),
                    FilledButton(
                      onPressed: _busy ? null : _send,
                      child: const Row(
                        spacing: AppSpacing.sm,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Kirim kode',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Ingat kata sandi?',
              style: text.bodyLarge!.copyWith(color: AppColors.muted),
            ),
            TextButton(
              onPressed: _toLogin,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              ),
              child: Text(
                'Masuk di sini',
                style: text.bodyLarge!.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    final text = Theme.of(context).textTheme;
    final caption = text.bodySmall!;
    final counting = _secondsLeft > 0;

    return Column(
      key: const ValueKey('sent'),
      children: [
        Column(
          spacing: AppSpacing.sm,
          children: [
            _Illustration(
              asset: AppSvg.sendCat,
              size: 140,
              glow: AppColors.secondarySoft,
            ),
            const _Heading(
              overline: 'Lupa kata sandi',
              title: 'Kode Berhasil Dikirim',
              body: 'Masukkan kode dari email, lalu buat kata sandi baru.',
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.page,
            bottom: AppSpacing.xl,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.12),
                  offset: const Offset(0, 4),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              spacing: AppSpacing.lg,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Row(
                    spacing: AppSpacing.sm,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.mail_outline,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      Flexible(
                        child: Text(
                          _email.text.trim(),
                          overflow: TextOverflow.ellipsis,
                          style: text.labelLarge!.copyWith(
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Column(
                    spacing: AppSpacing.sm,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Form(
                        key: _resetKey,
                        child: Column(
                          spacing: AppSpacing.lg,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _code,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              textAlign: TextAlign.center,
                              style: text.headlineMedium!.copyWith(
                                letterSpacing: 8,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                hintText: '000000',
                                counterText: '',
                              ),
                              validator: (v) => (v ?? '').length != 6
                                  ? 'Masukkan 6 digit kode'
                                  : null,
                            ),
                            AuthTextField(
                              label: 'Kata sandi baru',
                              hint: 'Minimal 8 karakter',
                              icon: Icons.lock_outline,
                              controller: _password,
                              obscure: true,
                              textInputAction: TextInputAction.next,
                              validator: (v) =>
                                  validateRequired(v) ??
                                  (v!.length < 8 ? 'Minimal 8 karakter' : null),
                            ),
                            AuthTextField(
                              label: 'Konfirmasi kata sandi',
                              hint: 'Ulangi kata sandi baru',
                              icon: Icons.lock_outline,
                              obscure: true,
                              textInputAction: TextInputAction.done,
                              validator: (v) =>
                                  validateRequired(v) ??
                                  (v != _password.text
                                      ? 'Kata sandi tidak sama'
                                      : null),
                            ),
                            FilledButton(
                              onPressed: _busy ? null : _reset,
                              child: const Text('Simpan kata sandi baru'),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('Belum menerima email?', style: caption),
                          TextButton(
                            onPressed: counting || _busy ? null : _resend,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                              ),
                              disabledForegroundColor: AppColors.primary,
                            ),
                            child: Text(
                              counting
                                  ? 'Kirim ulang (${_secondsLeft}s)'
                                  : 'Kirim ulang',
                              style: caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Butuh bantuan?', style: caption),
            TextButton(
              onPressed: () =>
                  showSupportContact(context, subject: 'Bantuan akun Meowville'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              ),
              child: Text(
                'Hubungi tim Meowville Care',
                style: caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({
    required this.asset,
    required this.size,
    required this.glow,
  });

  final String asset;
  final double size;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(width: size, height: size),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  glow.withValues(alpha: 0.6),
                  glow.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          SvgPicture.asset(asset, width: size * 0.9, height: size * 0.9),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({
    required this.overline,
    required this.title,
    required this.body,
  });

  final String overline;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      spacing: AppSpacing.sm,
      children: [
        Column(
          spacing: AppSpacing.xs,
          children: [
            Text(overline, style: AppText.overline),
            Text(title, textAlign: TextAlign.center, style: text.headlineLarge),
          ],
        ),
        Text(
          body,
          textAlign: TextAlign.center,
          style: text.bodyLarge!.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

class _Decor extends StatelessWidget {
  const _Decor({
    required this.child,
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.angle = 0,
    this.opacity = 1,
  });

  final Widget child;
  final double? top, left, right, bottom;
  final double angle;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Transform.rotate(angle: angle * math.pi / 180, child: child),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
