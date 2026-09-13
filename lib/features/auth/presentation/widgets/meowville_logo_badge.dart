import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_colors.dart';

class MeowvilleLogoBadge extends StatelessWidget {
  const MeowvilleLogoBadge({super.key, this.diameter = 80});

  static const String assetPath = 'assets/images/logo.png';

  final double diameter;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: diameter,
        height: diameter,
        padding: EdgeInsets.all(diameter * 0.075),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Color(0x14292725),
              offset: Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}
