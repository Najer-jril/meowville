import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_elevation.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/presentation/providers/auth_notifier.dart';
import '../../auth/presentation/widgets/meowville_logo_badge.dart';

class ShellTopBar extends StatefulWidget {
  const ShellTopBar({super.key});

  @override
  State<ShellTopBar> createState() => _ShellTopBarState();
}

class _ShellTopBarState extends State<ShellTopBar> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    if (_signingOut) {
      return;
    }
    setState(() => _signingOut = true);
    try {
      await context.read<AuthNotifier>().signOut();
    } on AppException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _signingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: AppElevation.topBar,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: SizedBox(
        height: AppSpacing.topBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdge,
          ),
          child: Row(
            children: <Widget>[
              const MeowvilleLogoBadge(diameter: 32),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: Text(
                  'Meowville',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headlineSm,
                ),
              ),
              _SignOutButton(signingOut: _signingOut, onPressed: _signOut),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.signingOut, required this.onPressed});

  final bool signingOut;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.controlAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: signingOut ? null : onPressed,
        borderRadius: AppRadius.controlAll,
        hoverColor: AppColors.surfaceContainer,
        highlightColor: AppColors.surfaceRecessed,
        focusColor: AppColors.surfaceRecessed,
        child: Tooltip(
          message: 'Keluar akun',
          child: SizedBox(
            width: AppSpacing.minTapTarget,
            height: AppSpacing.minTapTarget,
            child: Semantics(
              button: true,
              enabled: !signingOut,
              label: signingOut ? 'Sedang keluar akun' : 'Keluar akun',
              child: Center(
                child: signingOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onSurfaceVariant,
                        ),
                      )
                    : const Icon(
                        Icons.logout_rounded,
                        size: 22,
                        color: AppColors.onSurface,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
