import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppInlineLink extends StatefulWidget {
  const AppInlineLink({
    super.key,
    required this.text,
    required this.onTap,
    this.style,
    this.color = AppColors.brandTerracottaDark,
  });

  final String text;
  final VoidCallback onTap;
  final TextStyle? style;
  final Color color;

  @override
  State<AppInlineLink> createState() => _AppInlineLinkState();
}

class _AppInlineLinkState extends State<AppInlineLink> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = widget.style ?? AppTypography.labelLg;

    return Semantics(
      link: true,
      label: widget.text,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.base),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onFocusChange: (bool focused) => setState(() => _focused = focused),
            borderRadius: BorderRadius.circular(AppRadius.base),
            hoverColor: AppColors.surfaceContainer,
            focusColor: AppColors.surfaceContainer,
            // Area sentuh 44px walau teksnya pendek.
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.minTapTarget,
                minWidth: AppSpacing.minTapTarget,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
              ),
              // widthFactor 1: link selebar teksnya, tidak melebar penuh di Row/Wrap.
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Text(
                  widget.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: base.copyWith(
                    color: widget.color,
                    decoration: TextDecoration.underline,
                    decorationColor: widget.color,
                    decorationThickness: _focused ? 2 : 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
