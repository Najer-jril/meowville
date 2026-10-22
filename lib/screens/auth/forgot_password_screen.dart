import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_assets.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/auth_header.dart';

const _resendSeconds = 60;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;
  int _secondsLeft = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
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

  void _send() {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _sent = true);
    _startCountdown();
  }

  void _resend() {
    _startCountdown();
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
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _sent ? _buildSuccess() : _buildForm(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
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
        _Illustration(
          asset: AppSvg.envelopeCat,
          size: 176,
          glow: AppColors.primarySoft,
        ),
        const SizedBox(height: AppSpacing.sm),
        _Heading(
          overline: 'Lupa kata sandi',
          title: 'Aman, kami bantu',
          body: 'Masukkan email akun Anda. Kami akan mengirim tautan untuk mengatur ulang kata sandi.',
        ),
        const SizedBox(height: AppSpacing.page),
        Transform.translate(
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
                  const SizedBox(height: AppSpacing.page),
                  FilledButton(
                    onPressed: _send,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'Kirim tautan reset',
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
        ),
        const SizedBox(height: AppSpacing.lg),
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
        _Illustration(
          asset: AppSvg.sendCat,
          size: 140,
          glow: AppColors.secondarySoft,
        ),
        const SizedBox(height: AppSpacing.sm),
        const _Heading(
          overline: 'Lupa kata sandi',
          title: 'Tautan Berhasil Dikirim',
          body: 'Kami telah mengirimkan instruksi pemulihan ke alamat email Anda.',
        ),
        const SizedBox(height: AppSpacing.page),
        Container(
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
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.soft,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 28,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Tautan terkirim', style: text.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Cek kotak masuk email Anda. Jika tidak ada, periksa folder spam.',
                textAlign: TextAlign.center,
                style: text.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.mail_outline,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
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
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (_) => false,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.surface.withValues(alpha: 0.7),
                  foregroundColor: AppColors.primary,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back, size: 20),
                    SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        'Kembali ke halaman masuk',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Belum menerima email?', style: caption),
                  TextButton(
                    onPressed: counting ? null : _resend,
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
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Butuh bantuan?', style: caption),
            TextButton(
              onPressed: () {},
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
    return SizedBox(
      width: size,
      height: size,
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
      children: [
        Text(overline, style: AppText.overline),
        const SizedBox(height: AppSpacing.xs),
        Text(title, textAlign: TextAlign.center, style: text.headlineLarge),
        const SizedBox(height: AppSpacing.sm),
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
