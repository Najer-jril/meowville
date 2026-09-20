import 'package:flutter/widgets.dart';

import '../role_home_config.dart';
import '../widgets/role_home_scaffold.dart';

class SitterHomeScreen extends StatelessWidget {
  const SitterHomeScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const RoleHomeScaffold(config: RoleHomeConfig.sitter);
}
