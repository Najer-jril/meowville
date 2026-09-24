import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_inline_link.dart';

class DashboardSection extends StatelessWidget {
  const DashboardSection({
    super.key,
    required this.title,
    required this.child,
    this.linkLabel,
    this.onLinkTap,
  });

  final String title;
  final Widget child;
  final String? linkLabel;
  final VoidCallback? onLinkTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title, style: AppTypography.headlineSm),
              ),
            ),
            if (linkLabel != null && onLinkTap != null)
              Flexible(
                child: AppInlineLink(text: linkLabel!, onTap: onLinkTap!),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.space12),
        child,
      ],
    );
  }
}
