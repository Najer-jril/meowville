import 'package:flutter/widgets.dart';

import '../role_home_config.dart';
import '../widgets/role_home_scaffold.dart';

class OwnerHomeScreen extends StatelessWidget {
  const OwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const RoleHomeScaffold(config: RoleHomeConfig.owner);
}
