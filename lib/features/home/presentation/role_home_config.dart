import '../../auth/domain/entities/user_role.dart';

class RoleHomeConfig {
  const RoleHomeConfig({required this.role, required this.route});

  final UserRole role;
  final String route;

  static const String ownerRoute = '/pemilik';
  static const String sitterRoute = '/penjaga';
  static const String adminRoute = '/admin';

  static const RoleHomeConfig owner = RoleHomeConfig(
    role: UserRole.petOwner,
    route: ownerRoute,
  );

  static const RoleHomeConfig sitter = RoleHomeConfig(
    role: UserRole.petSitter,
    route: sitterRoute,
  );

  static const RoleHomeConfig admin = RoleHomeConfig(
    role: UserRole.admin,
    route: adminRoute,
  );

  static const List<RoleHomeConfig> all = <RoleHomeConfig>[
    owner,
    sitter,
    admin,
  ];

  static RoleHomeConfig forRole(UserRole role) => switch (role) {
    UserRole.petOwner => owner,
    UserRole.petSitter => sitter,
    UserRole.admin => admin,
  };

  static UserRole? roleForLocation(String location) {
    for (final RoleHomeConfig config in all) {
      if (location == config.route || location.startsWith('${config.route}/')) {
        return config.role;
      }
    }
    return null;
  }

  static bool isRoleRoute(String location) => roleForLocation(location) != null;
}
