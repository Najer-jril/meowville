import '../../../../core/utils/relative_date.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../dashboard/data/models/json_readers.dart';
import '../../domain/entities/staff_account.dart';

class StaffAccountDto {
  const StaffAccountDto._(this._json);

  factory StaffAccountDto.fromJson(Map<String, dynamic> json) =>
      StaffAccountDto._(json);

  final Map<String, dynamic> _json;

  StaffAccount toEntity() {
    return StaffAccount(
      id: _json['id'] as String,
      name: asNonEmptyString(_json['name']) ?? 'Tanpa nama',
      email: asNonEmptyString(_json['email']) ?? '',
      role: UserRole.fromWireValue(_json['role'] as String),
      createdAt: parseServerTimestamp(_json['created_at'] as String),
    );
  }
}
