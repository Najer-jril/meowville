import 'package:flutter_test/flutter_test.dart';
import 'package:meowville/core/errors/app_exception.dart';
import 'package:meowville/features/admin_manage/domain/entities/staff_account.dart';
import 'package:meowville/features/admin_manage/domain/entities/staff_draft.dart';
import 'package:meowville/features/admin_manage/domain/usecases/staff_usecases.dart';
import 'package:meowville/features/auth/domain/entities/user_role.dart';

import 'fake_admin_staff_repository.dart';

void main() {
  StaffDraft draft({
    String name = 'Rian Hidayat',
    String email = 'Rian@Contoh.com ',
    String password = 'rahasia123',
    UserRole? role = UserRole.petSitter,
  }) => StaffDraft(name: name, email: email, password: password, role: role);

  group('StaffDraft.validate', () {
    test('isian lengkap tidak punya galat', () {
      expect(draft().validate(), isEmpty);
    });

    test('menandai setiap kolom yang salah', () {
      final Map<StaffField, String> errors = draft(
        name: '   ',
        email: 'bukan-email',
        password: 'pendek',
        role: null,
      ).validate();

      expect(errors.keys, containsAll(StaffField.values));
    });

    test('pawrent bukan hak akses staf', () {
      expect(
        draft(role: UserRole.petOwner).validate().keys,
        contains(StaffField.role),
      );
    });

    test('nama lebih dari 100 karakter ditolak', () {
      expect(
        draft(name: 'a' * 101).validate().keys,
        contains(StaffField.name),
      );
    });
  });

  group('CreateStaffAccountUseCase', () {
    test('mengirim nama rapi dan email huruf kecil', () async {
      final FakeAdminStaffRepository repository = FakeAdminStaffRepository();

      await CreateStaffAccountUseCase(
        repository,
      )(draft(name: '  Rian Hidayat ', role: UserRole.admin));

      expect(repository.created.single.name, 'Rian Hidayat');
      expect(repository.created.single.email, 'rian@contoh.com');
      expect(repository.created.single.role, UserRole.admin);
    });

    test('isian salah tidak sampai ke server', () async {
      final FakeAdminStaffRepository repository = FakeAdminStaffRepository();

      await expectLater(
        CreateStaffAccountUseCase(repository)(draft(password: '123')),
        throwsA(isA<ValidationException>()),
      );
      expect(repository.created, isEmpty);
    });

    test('email yang sudah dipakai diteruskan sebagai konflik', () async {
      final FakeAdminStaffRepository repository = FakeAdminStaffRepository(
        createError: const ConflictException('Email ini sudah dipakai.'),
      );

      await expectLater(
        CreateStaffAccountUseCase(repository)(draft()),
        throwsA(isA<ConflictException>()),
      );
    });
  });

  test('filterStaffAccounts menyaring per peran, null berarti semua', () {
    final List<StaffAccount> accounts = <StaffAccount>[
      staffAccount(),
      staffAccount(id: 'b', name: 'Bagus', role: UserRole.admin),
    ];

    expect(filterStaffAccounts(accounts), hasLength(2));
    expect(
      filterStaffAccounts(accounts, role: UserRole.admin).single.name,
      'Bagus',
    );
  });
}
