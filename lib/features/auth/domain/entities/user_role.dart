enum UserRole {
  petOwner('pet_owner'),
  petSitter('pet_sitter'),
  admin('admin');

  const UserRole(this.wireValue);

  final String wireValue;

  static UserRole fromWireValue(String value) {
    return UserRole.values.firstWhere(
      (UserRole role) => role.wireValue == value,
      orElse: () => UserRole.petOwner,
    );
  }
}
