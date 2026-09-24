import 'package:meowville/core/errors/app_exception.dart';
import 'package:meowville/features/admin_manage/domain/entities/staff_account.dart';
import 'package:meowville/features/admin_manage/domain/repositories/admin_staff_repository.dart';
import 'package:meowville/features/auth/domain/entities/user_role.dart';

StaffAccount staffAccount({
  String id = '00000000-0000-4000-8000-000000000101',
  String name = 'Dinda Kirana',
  String email = 'dinda@contoh.com',
  UserRole role = UserRole.petSitter,
}) {
  return StaffAccount(
    id: id,
    name: name,
    email: email,
    role: role,
    createdAt: DateTime(2026, 9, 3, 10),
  );
}

typedef CreateStaffCall = ({
  String name,
  String email,
  String password,
  UserRole role,
});

class FakeAdminStaffRepository implements AdminStaffRepository {
  FakeAdminStaffRepository({
    List<StaffAccount>? accounts,
    this.loadError,
    this.createError,
    this.gate,
  }) : accounts = accounts ?? <StaffAccount>[];

  List<StaffAccount> accounts;
  AppException? loadError;
  AppException? createError;
  Future<void>? gate;
  final List<CreateStaffCall> created = <CreateStaffCall>[];
  int loadCount = 0;

  @override
  Future<List<StaffAccount>> loadStaff() async {
    loadCount++;
    if (gate != null) {
      await gate;
    }
    if (loadError != null) {
      throw loadError!;
    }
    return accounts;
  }

  @override
  Future<void> createStaff({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    if (createError != null) {
      throw createError!;
    }
    created.add((name: name, email: email, password: password, role: role));
    accounts = <StaffAccount>[
      StaffAccount(
        id: '00000000-0000-4000-8000-00000000${900 + created.length}',
        name: name,
        email: email,
        role: role,
        createdAt: DateTime(2026, 10, 12, 14),
      ),
      ...accounts,
    ];
  }
}
