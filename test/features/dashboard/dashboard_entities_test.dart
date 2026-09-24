import 'package:flutter_test/flutter_test.dart';
import 'package:meowville/features/dashboard/domain/entities/admin_dashboard.dart';
import 'package:meowville/features/dashboard/domain/entities/booking_status.dart';
import 'package:meowville/features/dashboard/domain/entities/booking_summary.dart';
import 'package:meowville/features/dashboard/domain/entities/daily_log_entry.dart';
import 'package:meowville/features/dashboard/domain/entities/owner_dashboard.dart';
import 'package:meowville/features/dashboard/domain/entities/pet_summary.dart';
import 'package:meowville/features/dashboard/domain/entities/sitter_dashboard.dart';
import 'package:meowville/features/dashboard/domain/entities/tier_occupancy.dart';

import 'dashboard_fixtures.dart';

void main() {
  group('BookingSummary', () {
    test('kode reservasi delapan karakter pertama id, huruf kecil', () {
      final BookingSummary b = booking(
        id: '3F9A2B41-0000-4000-8000-000000000001',
      );
      expect(b.code, '#3f9a2b41');
    });

    test(
      'jumlah malam dan hari ke-N benar untuk booking yang mulai kemarin',
      () {
        final BookingSummary b = booking(
          status: BookingStatus.checkedIn,
          checkin: day(-1),
          checkout: day(2),
        );
        expect(b.nights, 3);
        expect(b.stayDay(today), 2);
      },
    );
  });

  group('OwnerDashboard.compose', () {
    test('memilah aktif, mendatang, dan riwayat dari data', () {
      final BookingSummary active = booking(
        id: 'a0000000-0000-4000-8000-000000000001',
        status: BookingStatus.checkedIn,
        checkin: day(-1),
        checkout: day(2),
      );
      final BookingSummary soon = booking(
        id: 'b0000000-0000-4000-8000-000000000002',
        checkin: day(4),
        checkout: day(6),
      );
      final BookingSummary later = booking(
        id: 'c0000000-0000-4000-8000-000000000003',
        status: BookingStatus.pending,
        checkin: day(20),
        checkout: day(22),
      );
      final BookingSummary past = booking(
        id: 'd0000000-0000-4000-8000-000000000004',
        status: BookingStatus.checkedOut,
        checkin: day(-10),
        checkout: day(-7),
      );

      final OwnerDashboard dashboard = OwnerDashboard.compose(
        bookings: <BookingSummary>[later, active, past, soon],
        pets: const <PetSummary>[],
        rooms: const [],
        todayLogs: const [],
        today: today,
      );

      expect(dashboard.active, active);
      expect(dashboard.upcoming, <BookingSummary>[soon, later]);
      expect(dashboard.history, <BookingSummary>[past]);
      expect(dashboard.stayState, OwnerStayState.active);
      expect(dashboard.stayingPetIds, <String>{miko.id});
    });

    test(
      'tanpa aktif, kartu mendatang dipakai; tanpa keduanya, keadaan kosong',
      () {
        final OwnerDashboard upcomingOnly = OwnerDashboard.compose(
          bookings: <BookingSummary>[
            booking(checkin: day(3), checkout: day(5)),
          ],
          pets: const [],
          rooms: const [],
          todayLogs: const [],
          today: today,
        );
        expect(upcomingOnly.stayState, OwnerStayState.upcoming);

        final OwnerDashboard empty = OwnerDashboard.compose(
          bookings: const [],
          pets: const [],
          rooms: const [],
          todayLogs: const [],
          today: today,
        );
        expect(empty.stayState, OwnerStayState.none);
      },
    );

    test('booking Pending yang tanggalnya sudah lewat masuk riwayat', () {
      final BookingSummary stale = booking(
        status: BookingStatus.pending,
        checkin: day(-3),
        checkout: day(-1),
      );
      final OwnerDashboard dashboard = OwnerDashboard.compose(
        bookings: <BookingSummary>[stale],
        pets: const [],
        rooms: const [],
        todayLogs: const [],
        today: today,
      );
      expect(dashboard.upcoming, isEmpty);
      expect(dashboard.history, <BookingSummary>[stale]);
    });

    test('riwayat dibatasi lima terbaru', () {
      final List<BookingSummary> many = <BookingSummary>[
        for (int i = 0; i < 8; i++)
          booking(
            id: '${i}0000000-0000-4000-8000-000000000000',
            status: BookingStatus.checkedOut,
            checkin: day(-30 + i),
            checkout: day(-28 + i),
          ),
      ];
      final OwnerDashboard dashboard = OwnerDashboard.compose(
        bookings: many,
        pets: const [],
        rooms: const [],
        todayLogs: const [],
        today: today,
      );
      expect(dashboard.history, hasLength(5));
      expect(dashboard.history.first.checkin, day(-23));
    });
  });

  group('SitterDashboard', () {
    final BookingSummary arrived = booking(
      id: 'a0000000-0000-4000-8000-000000000001',
      status: BookingStatus.checkedIn,
      checkin: day(-1),
      checkout: day(0),
      pet: miko,
      assignedSitterId: 's1',
    );
    final BookingSummary staying = booking(
      id: 'b0000000-0000-4000-8000-000000000002',
      status: BookingStatus.checkedIn,
      checkin: day(-2),
      checkout: day(3),
      pet: luna,
      assignedSitterId: 's1',
    );
    final BookingSummary waiting = booking(
      id: 'c0000000-0000-4000-8000-000000000003',
      status: BookingStatus.confirmed,
      checkin: day(0),
      checkout: day(2),
      assignedSitterId: 's1',
    );

    test(
      'laporan tertunda terhitung benar saat sebagian tamu sudah punya log',
      () {
        final SitterDashboard dashboard = SitterDashboard.compose(
          guests: <BookingSummary>[arrived, staying, waiting],
          todayLogs: <DailyLogEntry>[logFor(arrived)],
          today: today,
        );

        expect(dashboard.stayingCount, 2);
        expect(dashboard.pendingReportGuests, <BookingSummary>[staying]);
        expect(dashboard.completedReportGuests, <BookingSummary>[arrived]);
        expect(dashboard.pendingReportCount, 1);
      },
    );

    test('angka check-in dan check-out hari ini diturunkan dari data', () {
      final SitterDashboard dashboard = SitterDashboard.compose(
        guests: <BookingSummary>[arrived, staying, waiting],
        todayLogs: const [],
        today: today,
      );

      expect(dashboard.checkinTodayCount, 1);
      expect(dashboard.waitingTodayCount, 1);
      expect(dashboard.arrivedTodayCount, 0);
      expect(dashboard.checkoutTodayCount, 1);
    });

    test('tugas berurutan: check-in dan check-out dulu, laporan menyusul', () {
      final SitterDashboard dashboard = SitterDashboard.compose(
        guests: <BookingSummary>[staying, arrived, waiting],
        todayLogs: const [],
        today: today,
      );

      expect(
        dashboard.tasks.map((SitterTask t) => t.kind).toList(),
        <SitterTaskKind>[
          SitterTaskKind.checkIn,
          SitterTaskKind.checkOut,
          SitterTaskKind.report,
          SitterTaskKind.report,
        ],
      );
    });

    test('tanpa penugasan, semua hitungan nol dan tugas kosong', () {
      final SitterDashboard dashboard = SitterDashboard.compose(
        guests: const [],
        todayLogs: const [],
        today: today,
      );
      expect(dashboard.tasks, isEmpty);
      expect(dashboard.stayingCount, 0);
    });
  });

  group('AdminDashboard.compose', () {
    const List<RoomUnitInfo> units = <RoomUnitInfo>[
      RoomUnitInfo(id: 1, roomId: 1, unitCode: 'STD-01'),
      RoomUnitInfo(id: 2, roomId: 1, unitCode: 'STD-02'),
      RoomUnitInfo(id: 3, roomId: 1, unitCode: 'STD-03'),
      RoomUnitInfo(id: 4, roomId: 1, unitCode: 'STD-04'),
      RoomUnitInfo(id: 5, roomId: 2, unitCode: 'DLX-01'),
      RoomUnitInfo(id: 6, roomId: 2, unitCode: 'DLX-02'),
    ];

    AdminDashboard compose({
      required List<BookingSummary> live,
      List<RoomBlockInfo> blocks = const <RoomBlockInfo>[],
      List<BookingSummary>? recent,
    }) {
      return AdminDashboard.compose(
        liveBookings: live,
        recent: recent ?? live,
        rooms: const [standardTier, deluxeTier],
        units: units,
        blocks: blocks,
        todayLogs: const [],
        servicesByBooking: const <String, List<String>>{},
        today: today,
      );
    }

    test('okupansi tidak menghitung Pending, Rejected, atau Cancelled', () {
      final AdminDashboard dashboard = compose(
        live: <BookingSummary>[
          booking(
            id: 'a0000000-0000-4000-8000-000000000001',
            status: BookingStatus.confirmed,
          ),
          booking(
            id: 'b0000000-0000-4000-8000-000000000002',
            status: BookingStatus.pending,
          ),
          booking(
            id: 'c0000000-0000-4000-8000-000000000003',
            status: BookingStatus.rejected,
          ),
          booking(
            id: 'd0000000-0000-4000-8000-000000000004',
            status: BookingStatus.cancelled,
          ),
        ],
      );

      final TierOccupancy standard = dashboard.occupancy.first;
      expect(standard.totalUnits, 4);
      expect(standard.occupiedUnits, 1);
    });

    test('okupansi benar saat ada room_blocks yang berlaku hari ini', () {
      final AdminDashboard dashboard = compose(
        live: <BookingSummary>[
          booking(
            id: 'a0000000-0000-4000-8000-000000000001',
            status: BookingStatus.checkedIn,
          ),
          booking(
            id: 'b0000000-0000-4000-8000-000000000002',
            status: BookingStatus.confirmed,
          ),
        ],
        blocks: const <RoomBlockInfo>[
          RoomBlockInfo(
            roomId: 1,
            blockedUnits: 1,
            purpose: 'Pembersihan menyeluruh',
          ),
        ],
      );

      final TierOccupancy standard = dashboard.occupancy.first;
      expect(standard.occupiedUnits, 2);
      expect(standard.blockedUnits, 1);
      expect(standard.availableUnits, 1);
      expect(standard.blockedPurposes, <String>['Pembersihan menyeluruh']);
      expect(standard.percent, 50);
    });

    test('unit tersedia tidak pernah negatif', () {
      final AdminDashboard dashboard = compose(
        live: <BookingSummary>[
          booking(
            id: 'a0000000-0000-4000-8000-000000000001',
            status: BookingStatus.checkedIn,
            tier: deluxeTier,
          ),
          booking(
            id: 'b0000000-0000-4000-8000-000000000002',
            status: BookingStatus.checkedIn,
            tier: deluxeTier,
          ),
          booking(
            id: 'c0000000-0000-4000-8000-000000000003',
            status: BookingStatus.checkedIn,
            tier: deluxeTier,
          ),
        ],
      );
      final TierOccupancy deluxe = dashboard.occupancy.last;
      expect(deluxe.availableUnits, 0);
      expect(deluxe.filledUnits, 2);
      expect(deluxe.percent, 100);
    });

    test('daftar tunggu berurutan: yang terlama di atas', () {
      final BookingSummary newer = booking(
        id: 'a0000000-0000-4000-8000-000000000001',
        status: BookingStatus.pending,
        createdAt: DateTime(2026, 10, 11),
      );
      final BookingSummary older = booking(
        id: 'b0000000-0000-4000-8000-000000000002',
        status: BookingStatus.pending,
        createdAt: DateTime(2026, 10, 8),
      );
      final AdminDashboard dashboard = compose(
        live: <BookingSummary>[newer, older],
      );

      expect(dashboard.pending, <BookingSummary>[older, newer]);
      expect(dashboard.pendingCount, 2);
    });

    test('ringkasan check-in, check-out, dan kapasitas', () {
      final AdminDashboard dashboard = compose(
        live: <BookingSummary>[
          booking(
            id: 'a0000000-0000-4000-8000-000000000001',
            status: BookingStatus.checkedIn,
            checkin: day(0),
            checkout: day(2),
          ),
          booking(
            id: 'b0000000-0000-4000-8000-000000000002',
            status: BookingStatus.confirmed,
            checkin: day(0),
            checkout: day(1),
          ),
          booking(
            id: 'c0000000-0000-4000-8000-000000000003',
            status: BookingStatus.checkedIn,
            checkin: day(-2),
            checkout: day(0),
          ),
        ],
      );

      expect(dashboard.checkinTodayCount, 2);
      expect(dashboard.arrivedTodayCount, 1);
      expect(dashboard.waitingTodayCount, 1);
      expect(dashboard.checkoutTodayCount, 1);
      expect(dashboard.stayingCount, 2);
      expect(dashboard.totalUnits, 6);
      expect(dashboard.capacityPercent, 50);
    });

    test(
      'tamu CheckedIn tanpa log hari ini masuk daftar laporan belum masuk',
      () {
        final BookingSummary withLog = booking(
          id: 'a0000000-0000-4000-8000-000000000001',
          status: BookingStatus.checkedIn,
        );
        final BookingSummary withoutLog = booking(
          id: 'b0000000-0000-4000-8000-000000000002',
          status: BookingStatus.checkedIn,
          pet: luna,
        );
        final AdminDashboard dashboard = AdminDashboard.compose(
          liveBookings: <BookingSummary>[withLog, withoutLog],
          recent: const [],
          rooms: const [standardTier],
          units: units,
          blocks: const [],
          todayLogs: <DailyLogEntry>[logFor(withLog)],
          servicesByBooking: const <String, List<String>>{},
          today: today,
        );
        expect(dashboard.missingReports, <BookingSummary>[withoutLog]);
      },
    );
  });
}
