import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../theme/app_assets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();
  late final _dots = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intro.dispose();
    _dots.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final intro = CurvedAnimation(parent: _intro, curve: Curves.easeOutQuart);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          _Paw(
            pulse: _pulse,
            phase: 0,
            opacity: 0.35,
            size: 144,
            left: -24,
            top: -16,
          ),
          _Paw(
            pulse: _pulse,
            phase: 0.33,
            opacity: 0.30,
            size: 176,
            right: -32,
            topFraction: 1 / 3,
            angle: -25,
          ),
          _Paw(
            pulse: _pulse,
            phase: 0.66,
            opacity: 0.30,
            size: 128,
            left: -16,
            bottom: 96,
            angle: 12,
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 288,
                          height: 288,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.secondarySoft.withValues(alpha: 0.9),
                                AppColors.bg.withValues(alpha: 0),
                              ],
                              stops: const [0, 0.7],
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: intro,
                              builder: (context, child) => Opacity(
                                opacity: intro.value,
                                child: Transform.translate(
                                  offset: Offset(0, 8 * (1 - intro.value)),
                                  child: Transform.scale(
                                    scale: 0.86 + 0.14 * intro.value,
                                    child: child,
                                  ),
                                ),
                              ),
                              child: const _Logo(),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Meowville',
                              style: text.headlineLarge!.copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                              ),
                              child: Text(
                                'Rumah kedua yang nyaman untuk kucing kesayanganmu',
                                textAlign: TextAlign.center,
                                style: text.bodyLarge!.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                _LoadingDots(animation: _dots),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: SvgPicture.asset(AppSvg.villageCat, fit: BoxFit.fill),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: AppShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const ColoredBox(
          color: AppColors.primarySoft,
          child: Center(
            child: Icon(Icons.pets, size: 56, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _Paw extends StatelessWidget {
  const _Paw({
    required this.pulse,
    required this.phase,
    required this.opacity,
    required this.size,
    this.left,
    this.right,
    this.top,
    this.bottom,
    this.topFraction,
    this.angle = 0,
  });

  final Animation<double> pulse;
  final double phase;
  final double opacity;
  final double size;
  final double? left, right, top, bottom, topFraction;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return Positioned(
      left: left,
      right: right,
      bottom: bottom,
      top: topFraction != null ? height * topFraction! : top,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: pulse,
          builder: (context, child) {
            final wave = math.cos(2 * math.pi * (pulse.value + phase));
            return Opacity(
              opacity: opacity * (0.75 + 0.25 * wave),
              child: child,
            );
          },
          child: Transform.rotate(
            angle: angle * math.pi / 180,
            child: SvgPicture.asset(AppSvg.pawSmall, width: size, height: size),
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    const delays = [0.0, 0.2, 0.4];
    return Semantics(
      label: 'Memuat aplikasi',
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < delays.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Transform.translate(
                offset: Offset(
                  0,
                  -8 *
                      math.max(
                        0,
                        math.sin(2 * math.pi * (animation.value - delays[i])),
                      ),
                ),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
