import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/domain/entities/user_role.dart';
import 'nav_destination.dart';
import 'role_bottom_nav.dart';
import 'shell_top_bar.dart';

class RoleShell extends StatelessWidget {
  const RoleShell({
    super.key,
    required this.role,
    required this.location,
    required this.child,
  });

  final UserRole role;
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final List<NavDestination> destinations = RoleNavigation.forRole(role);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            const ShellTopBar(),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: RoleBottomNav(
        destinations: destinations,
        currentIndex: RoleNavigation.indexFor(destinations, location),
        onSelected: (NavDestination destination) =>
            context.go(destination.route),
      ),
    );
  }
}
