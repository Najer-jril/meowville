import '../../../auth/domain/entities/user_role.dart';
import '../entities/staff_account.dart';

abstract interface class AdminStaffRepository {
  Future<List<StaffAccount>> loadStaff();

  Future<void> createStaff({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  });
}
