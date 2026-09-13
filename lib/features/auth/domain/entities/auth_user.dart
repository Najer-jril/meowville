import 'user_role.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.whatsappNumber,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String whatsappNumber;
  final UserRole role;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AuthUser && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
