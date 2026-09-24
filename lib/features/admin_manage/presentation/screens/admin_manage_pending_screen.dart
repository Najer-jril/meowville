import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_back_link.dart';
import '../../../shell/presentation/screens/placeholder_screen.dart';
import '../admin_manage_routes.dart';

class AdminManagePendingScreen extends StatelessWidget {
  const AdminManagePendingScreen({
    super.key,
    required this.title,
    required this.summary,
  });

  final String title;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppBackLink(
          label: 'Kelola',
          onBack: () => context.canPop()
              ? context.pop()
              : context.go(AdminManageRoutes.hub),
        ),
        Expanded(
          child: PlaceholderScreen(title: title, summary: summary),
        ),
      ],
    );
  }
}
