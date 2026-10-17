import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, this.showTitle = true, required this.onBack});

  final bool showTitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: AppShadows.soft,
              ),
              child: IconButton(
                onPressed: onBack,
                tooltip: 'Kembali',
                icon: Icon(
                  Icons.arrow_back,
                  color: showTitle ? AppColors.text : AppColors.primary,
                ),
              ),
            ),
          ),
          if (showTitle)
            Text(
              'Meowville',
              style: Theme.of(context).textTheme.titleLarge!
                  .copyWith(fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }
}