import '../../../auth/domain/entities/user_role.dart';

const List<UserRole> staffRoles = <UserRole>[
  UserRole.petSitter,
  UserRole.admin,
];

String staffRoleLabel(UserRole role) => switch (role) {
  UserRole.petSitter => 'Penjaga',
  UserRole.admin => 'Admin',
  UserRole.petOwner => 'Pawrent',
};

class StaffAccount {
  const StaffAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime createdAt;
}

List<StaffAccount> filterStaffAccounts(
  List<StaffAccount> accounts, {
  UserRole? role,
}) {
  if (role == null) {
    return accounts;
  }
  return accounts
      .where((StaffAccount account) => account.role == role)
      .toList(growable: false);
}
