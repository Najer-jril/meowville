import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meowville/core/errors/app_exception.dart';
import 'package:meowville/features/admin_bookings/domain/entities/admin_booking.dart';
import 'package:meowville/features/admin_pawrents/domain/entities/pawrent.dart';
import 'package:meowville/features/admin_pawrents/presentation/widgets/pawrent_widgets.dart';
import 'package:meowville/features/auth/domain/entities/user_role.dart';
import 'package:meowville/features/dashboard/domain/entities/booking_status.dart';

import '../../support/app_harness.dart';
import '../admin_bookings/fake_admin_booking_repository.dart';
import '../auth/presentation/fake_auth_repository.dart';
import 'fake_admin_pawrent_repository.dart';

void main() {
  const String listRoute = '/admin/pawrent';
  const String citraId = '11111111-0000-4000-8000-000000000001';
  const String rezaId = '22222222-0000-4000-8000-000000000002';
  const String pendingId = '3f9a2b41-0000-4000-8000-000000000001';

  final PawrentDetail citra = PawrentDetail.compose(
    id: citraId,
    name: 'Citra Lestari',
    email: 'citra.lestari@contoh.com',
    joinedAt: DateTime(2024, 8, 12),
    pets: const <PawrentPet>[
      PawrentPet(
        id: 'p1',
        name: 'Milo',
        breed: 'British Shorthair',
        weightKg: 4.2,
        aggressiveness: 'Low',
      ),
    ],
    bookings: <PawrentBooking>[
      PawrentBooking(
        id: pendingId,
        status: BookingStatus.pending,
        checkin: DateTime(2026, 10, 15),
        checkout: DateTime(2026, 10, 18),
        totalPrice: 575000,
        petName: 'Milo',
        roomType: 'Deluxe',
      ),
      PawrentBooking(
        id: '5b9a2b41-0000-4000-8000-000000000003',
        status: BookingStatus.checkedIn,
        checkin: DateTime(2026, 10, 10),
        checkout: DateTime(2026, 10, 14),
        totalPrice: 300000,
        petName: 'Milo',
        roomType: 'Standard',
      ),
    ],
  );
  final PawrentDetail reza = PawrentDetail.compose(
    id: rezaId,
    name: 'Reza Gunawan',
    email: 'reza@contoh.com',
    joinedAt: DateTime(2025, 1, 3),
  );

  Future<FakeAdminPawrentRepository> open(
    WidgetTester tester, {
    required String location,
    List<PawrentDetail>? pawrents,
    AppException? error,
    Size size = const Size(393, 852),
  }) async {
    final FakeAuthRepository auth = FakeAuthRepository(
      initialUser: userWithRole(UserRole.admin),
    );
    addTearDown(auth.dispose);
    final FakeAdminPawrentRepository repository = FakeAdminPawrentRepository(
      pawrents: pawrents ?? <PawrentDetail>[citra, reza],
      error: error,
    );
    await pumpApp(
      tester,
      auth,
      adminPawrentRepository: repository,
      adminBookingRepository: FakeAdminBookingRepository(
        bookings: <AdminBooking>[
          adminBooking(id: pendingId, petName: 'Milo', ownerName: citra.name),
        ],
      ),
      location: location,
      size: size,
    );
    await tester.pumpAndSettle();
    return repository;
  }

  group('daftar pawrent', () {
    testWidgets('keadaan memuat menyebut apa yang dimuat', (tester) async {
      final Completer<void> gate = Completer<void>();
      final FakeAuthRepository auth = FakeAuthRepository(
        initialUser: userWithRole(UserRole.admin),
      );
      addTearDown(auth.dispose);
      await pumpApp(
        tester,
        auth,
        adminPawrentRepository: FakeAdminPawrentRepository(gate: gate.future),
        location: listRoute,
      );

      expect(find.text('Memuat daftar pawrent...'), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('galat memuat menampilkan pesan dan Coba Lagi', (tester) async {
      await open(
        tester,
        location: listRoute,
        error: const NetworkException(
          'Perangkat tidak dapat menghubungi server.',
        ),
      );

      expect(find.text('Daftar pawrent belum bisa dimuat'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('kartu memuat nama, email, jumlah, dan tanda menginap', (
      tester,
    ) async {
      await open(tester, location: listRoute);

      expect(find.byType(PawrentCard), findsNWidgets(2));
      expect(find.text('1 kucing  ·  2 reservasi'), findsOneWidget);
      expect(find.text('0 kucing  ·  0 reservasi'), findsOneWidget);
      expect(find.text('Sedang Menginap'), findsOneWidget);
      expect(find.text('Semua (2)'), findsOneWidget);
      expect(find.text('Sedang Menginap (1)'), findsOneWidget);
    });

    testWidgets('setiap filter yang kosong punya keadaan kosong', (
      tester,
    ) async {
      await open(tester, location: listRoute, pawrents: <PawrentDetail>[]);
      expect(find.text('Belum ada pawrent terdaftar'), findsOneWidget);

      await tapVisible(tester, find.bySemanticsLabel('Sedang Menginap (0)'));
      await tester.pumpAndSettle();
      expect(
        find.text('Tidak ada kucing yang sedang menginap'),
        findsOneWidget,
      );
    });

    testWidgets('filter menginap dan pencarian menyaring kartu', (
      tester,
    ) async {
      await open(tester, location: listRoute);

      await tapVisible(tester, find.bySemanticsLabel('Sedang Menginap (1)'));
      await tester.pumpAndSettle();
      expect(find.byType(PawrentCard), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'reza');
      await tester.pumpAndSettle();
      expect(
        find.text('Tidak ada pawrent yang cocok dengan "reza"'),
        findsOneWidget,
      );

      await tapVisible(tester, find.text('Hapus pencarian'));
      await tester.pumpAndSettle();
      expect(find.byType(PawrentCard), findsOneWidget);
    });

    testWidgets('tidak meluap mendatar pada lebar 320 px', (tester) async {
      await open(tester, location: listRoute, size: const Size(320, 640));
      expect(tester.takeException(), isNull);
    });
  });

  group('detail pawrent', () {
    testWidgets('menampilkan kucing dan riwayat dengan total tersimpan', (
      tester,
    ) async {
      await open(tester, location: '$listRoute/$citraId');

      expect(find.text('Citra Lestari'), findsOneWidget);
      expect(find.text('Terdaftar sejak 12 Agu 2024'), findsOneWidget);
      expect(find.text('Kucing (1)'), findsOneWidget);
      expect(find.text('4,2 kg'), findsOneWidget);
      expect(find.text('Agresivitas rendah'), findsOneWidget);
      expect(find.text('Riwayat reservasi (2)'), findsOneWidget);
      expect(find.text('Rp 575.000'), findsOneWidget);
      expect(find.byType(PawrentBookingCard), findsNWidgets(2));
    });

    testWidgets('tanpa kucing dan reservasi menampilkan keadaan kosong', (
      tester,
    ) async {
      await open(tester, location: '$listRoute/$rezaId');

      expect(find.text('Belum ada kucing terdaftar'), findsOneWidget);
      expect(find.text('Belum ada reservasi'), findsOneWidget);
    });

    testWidgets('id tidak dikenal menampilkan galat', (tester) async {
      await open(tester, location: '$listRoute/tidak-ada');

      expect(find.text('Data pawrent belum bisa dimuat'), findsOneWidget);
    });

    testWidgets('riwayat membuka detail reservasi dengan aksi Pending', (
      tester,
    ) async {
      final FakeAdminPawrentRepository repository = await open(
        tester,
        location: '$listRoute/$citraId',
      );
      final int loadsBefore = repository.detailLoads;

      await tapVisible(tester, find.text('Rp 575.000'));
      await tester.pumpAndSettle();

      expect(find.text('Reservasi Milo'), findsOneWidget);
      expect(find.text('Detail pawrent'), findsOneWidget);
      expect(find.text('Setujui'), findsOneWidget);
      expect(find.text('Tolak'), findsOneWidget);

      await tapVisible(tester, find.text('Detail pawrent'));
      await tester.pumpAndSettle();
      expect(find.text('Riwayat reservasi (2)'), findsOneWidget);
      expect(repository.detailLoads, greaterThan(loadsBefore));
    });
  });
}
