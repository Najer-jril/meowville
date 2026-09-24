import 'package:flutter_test/flutter_test.dart';
import 'package:meowville/core/errors/app_exception.dart';
import 'package:meowville/features/admin_bookings/data/datasources/admin_booking_remote_datasource.dart';
import 'package:meowville/features/admin_bookings/data/repositories/admin_booking_repository_impl.dart';
import 'package:meowville/features/admin_bookings/domain/entities/admin_booking.dart';
import 'package:meowville/features/admin_bookings/domain/entities/booking_decision.dart';
import 'package:meowville/features/admin_bookings/domain/usecases/decide_booking_usecase.dart';
import 'package:meowville/features/dashboard/domain/entities/booking_status.dart';

import 'fake_admin_booking_repository.dart';

Map<String, dynamic> _row({
  String status = 'Pending',
  List<Map<String, dynamic>>? services,
}) {
  return <String, dynamic>{
    'id': '3f9a2b41-0000-4000-8000-000000000001',
    'status': status,
    'checkin_date': '2026-10-15',
    'checkout_date': '2026-10-18',
    'created_at': '2026-10-14T02:30:00',
    'total_price': '575000.00',
    'care_instructions': '  ',
    'pets': <String, dynamic>{
      'pet_name': 'Luna',
      'breed': 'Persia',
      'weight_kg': '3.80',
      'aggressiveness_level': 'High',
    },
    'rooms': <String, dynamic>{
      'room_type': 'Deluxe',
      'included_services': 'CCTV, Playtime',
    },
    'owner': <String, dynamic>{'name': 'Reza Gunawan', 'email': 'r@contoh.com'},
    'booking_services':
        services ??
        <Map<String, dynamic>>[
          <String, dynamic>{
            'price_at_booking': '50000.00',
            'services': <String, dynamic>{'service_name': 'Feliway'},
          },
          <String, dynamic>{
            'price_at_booking': 75000,
            'services': <String, dynamic>{'service_name': 'Grooming'},
          },
        ],
  };
}

class _FakeDataSource implements AdminBookingRemoteDataSource {
  _FakeDataSource({this.rows = const <JsonRow>[], this.changedRows = 1});

  final List<JsonRow> rows;
  final int changedRows;
  final List<Map<String, String>> updates = <Map<String, String>>[];

  @override
  Future<List<JsonRow>> bookings() async => rows;

  @override
  Future<JsonRow?> booking(String bookingId) async =>
      rows.where((JsonRow r) => r['id'] == bookingId).firstOrNull;

  @override
  Future<int> updateStatus({
    required String bookingId,
    required String fromStatus,
    required String toStatus,
    required String adminId,
  }) async {
    updates.add(<String, String>{
      'id': bookingId,
      'from': fromStatus,
      'to': toStatus,
      'admin': adminId,
    });
    return changedRows;
  }
}

void main() {
  group('BookingDecision', () {
    test('Pending: setujui dan tolak. Confirmed: batalkan', () {
      expect(
        BookingDecision.availableFor(BookingStatus.pending),
        <BookingDecision>[BookingDecision.approve, BookingDecision.reject],
      );
      expect(
        BookingDecision.availableFor(BookingStatus.confirmed),
        <BookingDecision>[BookingDecision.cancel],
      );
    });

    test('status lain hanya bisa dibaca', () {
      for (final BookingStatus status in <BookingStatus>[
        BookingStatus.checkedIn,
        BookingStatus.checkedOut,
        BookingStatus.rejected,
        BookingStatus.cancelled,
      ]) {
        expect(
          BookingDecision.availableFor(status),
          isEmpty,
          reason: '$status',
        );
      }
    });
  });

  group('AdminBooking', () {
    test('sewa kamar diturunkan dari total tersimpan dikurangi add-on', () {
      final AdminBooking booking = adminBooking(
        totalPrice: 575000,
        addOns: const <BookingAddOn>[
          BookingAddOn(name: 'Feliway', priceAtBooking: 50000),
          BookingAddOn(name: 'Grooming', priceAtBooking: 75000),
        ],
      );
      expect(booking.addOnTotal, 125000);
      expect(booking.roomSubtotal, 450000);
      expect(booking.nights, 3);
    });

    test('saringan status dan pencarian nama kucing atau pawrent', () {
      final List<AdminBooking> all = <AdminBooking>[
        adminBooking(id: 'a0000000-1', petName: 'Luna', ownerName: 'Reza'),
        adminBooking(
          id: 'b0000000-2',
          petName: 'Milo',
          ownerName: 'Citra Lestari',
          status: BookingStatus.confirmed,
        ),
      ];

      expect(filterAdminBookings(all), hasLength(2));
      expect(
        filterAdminBookings(
          all,
          status: BookingStatus.confirmed,
        ).single.petName,
        'Milo',
      );
      expect(
        filterAdminBookings(all, query: '  lestari ').single.petName,
        'Milo',
      );
      expect(filterAdminBookings(all, query: 'LUN').single.petName, 'Luna');
      expect(
        filterAdminBookings(all, status: BookingStatus.pending, query: 'milo'),
        isEmpty,
      );
    });
  });

  group('DecideBookingUseCase', () {
    test('meneruskan id admin sebagai confirmed_by', () async {
      final FakeAdminBookingRepository repository = FakeAdminBookingRepository(
        bookings: <AdminBooking>[adminBooking()],
      );
      await DecideBookingUseCase(repository)(
        booking: adminBooking(),
        decision: BookingDecision.approve,
        adminId: 'admin-1',
      );

      expect(repository.decisions.single.adminId, 'admin-1');
      expect(repository.decisions.single.decision, BookingDecision.approve);
    });

    test('menolak keputusan yang tidak sah untuk status saat ini', () async {
      final FakeAdminBookingRepository repository =
          FakeAdminBookingRepository();

      await expectLater(
        DecideBookingUseCase(repository)(
          booking: adminBooking(status: BookingStatus.checkedIn),
          decision: BookingDecision.cancel,
          adminId: 'admin-1',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(repository.decisions, isEmpty);
    });

    test('tanpa sesi admin tidak menulis apa pun', () async {
      final FakeAdminBookingRepository repository =
          FakeAdminBookingRepository();

      await expectLater(
        DecideBookingUseCase(repository)(
          booking: adminBooking(),
          decision: BookingDecision.reject,
          adminId: null,
        ),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(repository.decisions, isEmpty);
    });
  });

  group('AdminBookingRepositoryImpl', () {
    test('membaca baris Supabase beserta harga add-on snapshot', () async {
      final AdminBookingRepositoryImpl repository = AdminBookingRepositoryImpl(
        _FakeDataSource(rows: <JsonRow>[_row()]),
      );

      final AdminBooking b = (await repository.loadBookings()).single;
      expect(b.status, BookingStatus.pending);
      expect(b.totalPrice, 575000);
      expect(b.petWeightKg, 3.8);
      expect(b.petAggressiveness, 'High');
      expect(b.ownerEmail, 'r@contoh.com');
      expect(b.careInstructions, isNull);
      expect(b.addOns.map((BookingAddOn a) => a.priceAtBooking), <double>[
        50000,
        75000,
      ]);
      expect(b.roomSubtotal, 450000);
      expect(b.createdAt.toUtc(), DateTime.utc(2026, 10, 14, 2, 30));
    });

    test('id yang tidak ada menjadi NotFoundException', () async {
      final AdminBookingRepositoryImpl repository = AdminBookingRepositoryImpl(
        _FakeDataSource(),
      );
      await expectLater(
        repository.loadBooking('tidak-ada'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('menulis status tujuan, status asal, dan admin', () async {
      final _FakeDataSource source = _FakeDataSource();
      await AdminBookingRepositoryImpl(source).applyDecision(
        bookingId: 'b1',
        decision: BookingDecision.cancel,
        adminId: 'admin-1',
      );

      expect(source.updates.single, <String, String>{
        'id': 'b1',
        'from': 'Confirmed',
        'to': 'Cancelled',
        'admin': 'admin-1',
      });
    });

    test('nol baris berubah berarti status sudah lain di server', () async {
      await expectLater(
        AdminBookingRepositoryImpl(_FakeDataSource(changedRows: 0))
            .applyDecision(
              bookingId: 'b1',
              decision: BookingDecision.approve,
              adminId: 'admin-1',
            ),
        throwsA(isA<ConflictException>()),
      );
    });
  });
}
