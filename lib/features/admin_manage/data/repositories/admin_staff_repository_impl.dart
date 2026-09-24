import '../../../auth/domain/entities/user_role.dart';
import '../../domain/entities/staff_account.dart';
import '../../domain/repositories/admin_staff_repository.dart';
import '../datasources/admin_staff_remote_datasource.dart';
import '../models/staff_account_dto.dart';

class AdminStaffRepositoryImpl implements AdminStaffRepository {
  const AdminStaffRepositoryImpl(this._dataSource);

  final AdminStaffRemoteDataSource _dataSource;

  @override
  Future<List<StaffAccount>> loadStaff() async {
    final List<JsonRow> rows = await _dataSource.staff();
    return rows
        .map((JsonRow row) => StaffAccountDto.fromJson(row).toEntity())
        .toList(growable: false);
  }

  @override
  Future<void> createStaff({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) {
    return _dataSource.createStaff(
      name: name,
      email: email,
      password: password,
      role: role.wireValue,
    );
  }
}
