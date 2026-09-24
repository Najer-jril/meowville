import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class PetAvatar extends StatelessWidget {
  const PetAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 48,
  });

  static const double _radius = 14;

  final String name;
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Widget initial = _Initial(name: name, size: size);

    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: photoUrl == null
              ? initial
              : Image.network(
                  photoUrl!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (
                    BuildContext context,
                    Object error,
                    StackTrace? trace,
                  ) => initial,
                ),
        ),
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final String trimmed = name.trim();
    final String letter = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();

    return ColoredBox(
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Text(
          letter,
          style: AppTypography.headlineSm.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: size * 0.42,
          ),
        ),
      ),
    );
  }
}
