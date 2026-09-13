import '../../domain/entities/auth_user.dart';
import '../../domain/entities/user_role.dart';

class AuthUserDto {
  const AuthUserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.whatsappNumber,
    required this.role,
    required this.createdAt,
  });

  factory AuthUserDto.fromJson(Map<String, dynamic> json) {
    return AuthUserDto(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      whatsappNumber: json['whatsapp_number'] as String,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String name;
  final String email;
  final String whatsappNumber;
  final String role;
  final DateTime createdAt;

  Map<String, dynamic> toInsertJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'whatsapp_number': whatsappNumber,
      'role': role,
    };
  }

  AuthUser toEntity() {
    return AuthUser(
      id: id,
      name: name,
      email: email,
      whatsappNumber: whatsappNumber,
      role: UserRole.fromWireValue(role),
      createdAt: createdAt,
    );
  }
}
