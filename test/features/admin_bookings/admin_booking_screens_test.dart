import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meowville/core/errors/app_exception.dart';
import 'package:meowville/features/admin_bookings/domain/entities/admin_booking.dart';
import 'package:meowville/features/admin_bookings/domain/entities/booking_decision.dart';
import 'package:meowville/features/admin_bookings/presentation/widgets/admin_booking_card.dart';
import 'package:meowville/features/auth/domain/entities/user_role.dart';
import 'package:meowville/features/dashboard/domain/entities/booking_status.dart';
import 'package:meowville/features/dashboard/presentation/widgets/booking_status_badge.dart';

import '../../support/app_harness.dart';
import '../auth/presentation/fake_auth_repository.dart';
import 'fake_admin_booking_repository.dart';

void main() {
  const String listRoute = '/admin/reservasi';
  const String lunaId = '3f9a2b41-0000-4000-8000-000000000001';
  const String miloId = '4a9a2b41-0000-4000-8000-000000000002';

  final AdminBooking pendingLuna = adminBooking(
    id: lunaId,
    addOns: const <BookingAddOn>[
      BookingAddOn(name: 'Feliway Diffuser', priceAtBooking: 50000),
      BookingAddOn(name: 'Grooming Kepulangan', priceAtBooking: 75000),
    ],
  );
  final AdminBooking confirmedMilo = adminBooking(
    id: miloId,
    status: BookingStatus.confirmed,
    petName: 'Milo',
    petBreed: 'British Shorthair',
    ownerName: 'Citra Lestari',
    totalPrice: 300000,
  );

  Future<FakeAdminBookingRepository> open(
    WidgetTester tester, {
    required String location,
    List<AdminBooking>? bookings,
    AppException? error,
    Size size = const Size(393, 852),
  }) async {
    final FakeAuthRepository auth = FakeAuthRepository(
      initialUser: userWithRole(UserRole.admin),
    );
    addTearDown(auth.dispose);
    final FakeAdminBookingRepository repository = FakeAdminBookingRepository(
      bookings: bookings ?? <AdminBooking>[pendingLuna, confirmedMilo],
      error: error,
    );
    await pumpApp(
      tester,
      auth,
      adminBookingRepository: repository,
      location: location,
      size: size,
    );
    await tester.pumpAndSettle();
    return repository;
  }

  group('daftar reservasi', () {
    testWidgets('keadaan memuat menyebut apa yang dimuat', (tester) async {
      final Completer<void> gate = Completer<void>();
      final FakeAuthRepository auth = FakeAuthRepository(
        initialUser: userWithRole(UserRole.admin),
      );
      addTearDown(auth.dispose);
      await pumpApp(
        tester,
        auth,
        adminBookingRepository: FakeAdminBookingRepository(gate: gate.future),
        location: listRoute,
      );

      expect(find.text('Memuat daftar reservasi...'), findsOneWidget);
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

      expect(find.text('Daftar reservasi belum bisa dimuat'), findsOneWidget);
      expect(
        find.text('Perangkat tidak dapat menghubungi server.'),
        findsOneWidget,
      );
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('kartu memuat kucing, pawrent, tier, dan jumlah add-on', (
      tester,
    ) async {
      await open(tester, location: listRoute);

      expect(find.byType(AdminBookingCard), findsNWidgets(2));
      expect(find.text('Pawrent: Reza Gunawan'), findsOneWidget);
      expect(find.text('+2 add-on'), findsOneWidget);
      expect(find.text('1 reservasi menunggu keputusan Anda.'), findsOneWidget);
    });

    testWidgets('setiap filter status yang kosong punya keadaan kosong', (
      tester,
    ) async {
      await open(tester, location: listRoute, bookings: <AdminBooking>[]);
      expect(find.text('Belum ada reservasi'), findsOneWidget);

      for (final (BookingStatus status, String title)
          in <(BookingStatus, String)>[
            (BookingStatus.pending, 'Tidak ada reservasi yang menunggu'),
            (BookingStatus.confirmed, 'Belum ada reservasi dikonfirmasi'),
            (BookingStatus.checkedIn, 'Tidak ada kucing yang sedang menginap'),
            (BookingStatus.checkedOut, 'Belum ada reservasi selesai'),
            (BookingStatus.rejected, 'Belum ada reservasi ditolak'),
            (BookingStatus.cancelled, 'Belum ada reservasi dibatalkan'),
          ]) {
        final Finder chip = find.bySemanticsLabel(
          BookingStatusBadge.labelFor(status),
        );
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget, reason: '$status');
      }
    });

    testWidgets('filter status menyaring kartu', (tester) async {
      await open(tester, location: listRoute);

      await tapVisible(tester, find.bySemanticsLabel('Dikonfirmasi'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminBookingCard), findsOneWidget);
      expect(find.text('Pawrent: Citra Lestari'), findsOneWidget);
    });

    testWidgets('pencarian tanpa hasil menawarkan hapus pencarian', (
      tester,
    ) async {
      await open(tester, location: listRoute);

      await tester.enterText(find.byType(TextField), 'lestari');
      await tester.pumpAndSettle();
      expect(find.byType(AdminBookingCard), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('Tidak ada yang cocok dengan "zzz"'), findsOneWidget);

      await tapVisible(tester, find.text('Hapus pencarian'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminBookingCard), findsNWidgets(2));
    });

    testWidgets('mengetuk kartu membuka detail di bawah tab Reservasi', (
      tester,
    ) async {
      await open(tester, location: listRoute);

      await tester.tap(find.text('Pawrent: Reza Gunawan'));
      await tester.pumpAndSettle();

      expect(find.text('Reservasi Luna'), findsOneWidget);
      expect(find.text('Daftar reservasi'), findsOneWidget);
    });

    testWidgets('tidak meluap mendatar pada lebar 320 px', (tester) async {
      await open(tester, location: listRoute, size: const Size(320, 640));
      expect(tester.takeException(), isNull);
    });
  });

  group('detail reservasi', () {
    testWidgets('rincian biaya memakai total dan harga add-on tersimpan', (
      tester,
    ) async {
      await open(tester, location: '$listRoute/$lunaId');

      expect(find.text('Feliway Diffuser'), findsOneWidget);
      expect(find.text('Rp 50.000'), findsOneWidget);
      expect(find.text('Sewa kamar Deluxe, 3 malam'), findsOneWidget);
      expect(find.text('Rp 450.000'), findsOneWidget);
      expect(find.text('Rp 575.000'), findsOneWidget);
    });

    testWidgets('Pending: setujui lewat dialog menulis id admin', (
      tester,
    ) async {
      final FakeAdminBookingRepository repository = await open(
        tester,
        location: '$listRoute/$lunaId',
      );

      expect(find.bySemanticsLabel('Tolak'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Setujui'));
      await tester.pumpAndSettle();
      expect(find.text('Setujui reservasi Luna?'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Ya, setujui'));
      await tester.pumpAndSettle();

      final DecisionCall call = repository.decisions.single;
      expect(call.decision, BookingDecision.approve);
      expect(call.adminId, userWithRole(UserRole.admin).id);
      expect(find.text('Reservasi Luna disetujui.'), findsOneWidget);
      // Status baru dimuat ulang: kini Confirmed, jadi aksinya Batalkan.
      expect(find.bySemanticsLabel('Batalkan Reservasi'), findsOneWidget);
      expect(find.bySemanticsLabel('Setujui'), findsNothing);
    });

    testWidgets('Kembali di dialog tidak menulis apa pun', (tester) async {
      final FakeAdminBookingRepository repository = await open(
        tester,
        location: '$listRoute/$lunaId',
      );

      await tester.tap(find.bySemanticsLabel('Tolak'));
      await tester.pumpAndSettle();
      expect(find.textContaining('milik Reza Gunawan'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Kembali'));
      await tester.pumpAndSettle();

      expect(repository.decisions, isEmpty);
    });

    testWidgets('Confirmed: hanya Batalkan Reservasi', (tester) async {
      final FakeAdminBookingRepository repository = await open(
        tester,
        location: '$listRoute/$miloId',
      );

      expect(find.bySemanticsLabel('Setujui'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Batalkan Reservasi'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Ya, batalkan'));
      await tester.pumpAndSettle();

      expect(repository.decisions.single.decision, BookingDecision.cancel);
      expect(find.byType(BookingStatusBadge), findsOneWidget);
      expect(find.text('Dibatalkan'), findsOneWidget);
    });

    for (final BookingStatus status in <BookingStatus>[
      BookingStatus.checkedIn,
      BookingStatus.checkedOut,
      BookingStatus.rejected,
      BookingStatus.cancelled,
    ]) {
      testWidgets('${status.wireValue}: hanya baca, tanpa bilah aksi', (
        tester,
      ) async {
        await open(
          tester,
          location: '$listRoute/$lunaId',
          bookings: <AdminBooking>[adminBooking(id: lunaId, status: status)],
        );

        expect(find.text('Reservasi Luna'), findsOneWidget);
        for (final String label in <String>[
          'Setujui',
          'Tolak',
          'Batalkan Reservasi',
        ]) {
          expect(find.bySemanticsLabel(label), findsNothing);
        }
      });
    }

    testWidgets('gagal menyimpan memberi tahu lewat snackbar', (tester) async {
      final FakeAdminBookingRepository repository = await open(
        tester,
        location: '$listRoute/$lunaId',
      );
      repository.decisionError = const ConflictException(
        'Status reservasi sudah berubah.',
      );

      await tester.tap(find.bySemanticsLabel('Tolak'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Ya, tolak'));
      await tester.pumpAndSettle();

      expect(find.text('Status reservasi sudah berubah.'), findsOneWidget);
    });

    testWidgets('id yang tidak ada menampilkan keadaan galat', (tester) async {
      await open(tester, location: '$listRoute/tidak-ada');

      expect(find.text('Detail reservasi belum bisa dimuat'), findsOneWidget);
      expect(find.text('Reservasi ini tidak ditemukan.'), findsOneWidget);
    });

    testWidgets('detail tidak meluap pada 320 px', (tester) async {
      await open(
        tester,
        location: '$listRoute/$lunaId',
        size: const Size(320, 640),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
