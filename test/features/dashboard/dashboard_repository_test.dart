import 'package:flutter_test/flutter_test.dart';
import 'package:meowville/features/dashboard/data/models/booking_dto.dart';
import 'package:meowville/features/dashboard/data/models/daily_log_dto.dart';
import 'package:meowville/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:meowville/features/dashboard/domain/entities/admin_dashboard.dart';
import 'package:meowville/features/dashboard/domain/entities/booking_status.dart';
import 'package:meowville/features/dashboard/domain/entities/booking_summary.dart';
import 'package:meowville/features/dashboard/domain/entities/daily_log_entry.dart';
import 'package:meowville/features/dashboard/domain/entities/owner_dashboard.dart';
import 'package:meowville/features/dashboard/domain/entities/sitter_dashboard.dart';

import 'dashboard_fixtures.dart';

String _resolve(String bucket, String path) => 'https://cdn.test/$bucket/$path';

Map<String, dynamic> bookingRow({
  String id = '3f9a2b41-0000-4000-8000-000000000001',
  String status = 'Confirmed',
  String checkin = '2026-10-12',
  String checkout = '2026-10-15',
  int roomId = 1,
  Map<String, dynamic>? pet,
  String? proof,
  String? sitter,
  String? unit,
  String createdAt = '2026-10-10T02:00:00',
}) {
  return <String, dynamic>{
    'id': id,
    'status': status,
    'checkin_date': checkin,
    'checkout_date': checkout,
    'total_price': 225000,
    'care_instructions': null,
    'created_at': createdAt,
    'payment_proof_url': proof,
    'assigned_sitter_id': sitter,
    'pets':
        pet ??
        <String, dynamic>{
          'id': 'pet-1',
          'pet_name': 'Miko',
          'breed': 'Domestik',
          'sex': 'Jantan',
          'weight_kg': '4.20',
          'photo_url': 'miko.jpg',
        },
    'rooms': <String, dynamic>{
      'id': roomId,
      'room_type': roomId == 1 ? 'Standard' : 'Deluxe',
      'price_per_night': 75000,
    },
    'room_units': unit == null ? null : <String, dynamic>{'unit_code': unit},
    'owner': <String, dynamic>{'name': 'Rani Pratama'},
  };
}

void main() {
  group('BookingDto', () {
    test('membaca relasi tertanam, tanggal, dan foto', () {
      final BookingSummary b = BookingDto.fromJson(
        bookingRow(unit: 'STD-02', proof: 'u1/bukti.jpg', sitter: 's1'),
      ).toEntity(_resolve);

      expect(b.status, BookingStatus.confirmed);
      expect(b.checkin, DateTime(2026, 10, 12));
      expect(b.nights, 3);
      expect(b.pet.name, 'Miko');
      expect(b.pet.weightKg, 4.2);
      expect(b.pet.photoUrl, 'https://cdn.test/pet-photos/miko.jpg');
      expect(b.roomType, 'Standard');
      expect(b.unitCode, 'STD-02');
      expect(b.ownerName, 'Rani Pratama');
      expect(b.hasPaymentProof, isTrue);
      expect(b.assignedSitterId, 's1');
      expect(b.createdAt.toUtc(), DateTime.utc(2026, 10, 10, 2));
    });

    test('kolom opsional yang kosong tidak memecahkan pembacaan', () {
      final Map<String, dynamic> row = bookingRow()
        ..['pets'] = <String, dynamic>{
          'id': 'pet-9',
          'pet_name': 'Tigra',
          'breed': null,
          'photo_url': null,
        };
      final BookingSummary b = BookingDto.fromJson(row).toEntity(_resolve);

      expect(b.pet.photoUrl, isNull);
      expect(b.pet.breed, '');
      expect(b.unitCode, isNull);
      expect(b.hasPaymentProof, isFalse);
    });
  });

  group('DailyLogDto', () {
    test('memotong jam makan ke HH:mm dan membaca nama penulis', () {
      final DailyLogEntry log = DailyLogDto.fromJson(<String, dynamic>{
        'id': 'l1',
        'booking_id': 'b1',
        'log_date': '2026-10-12',
        'eating_time': '08:30:00',
        'pet_mood': 'Ceria',
        'note': 'Makan lahap.',
        'photo_url': 'l1.jpg',
        'created_at': '2026-10-12T01:45:00',
        'author': <String, dynamic>{'name': 'Gilang'},
      }).toEntity(_resolve);

      expect(log.eatingTime, '08:30');
      expect(log.authorName, 'Gilang');
      expect(log.photoUrl, 'https://cdn.test/log-photos/l1.jpg');
    });
  });

  group('DashboardRepositoryImpl', () {
    test('pemilik: laporan hanya ditarik saat ada reservasi aktif', () async {
      final FakeDashboardDataSource withActive = FakeDashboardDataSource(
        bookings: <Map<String, dynamic>>[
          bookingRow(
            status: 'CheckedIn',
            checkin: '2026-10-11',
            checkout: '2026-10-14',
          ),
        ],
        logs: <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'l1',
            'booking_id': '3f9a2b41-0000-4000-8000-000000000001',
            'log_date': '2026-10-12',
          },
        ],
      );
      final OwnerDashboard active = await DashboardRepositoryImpl(
        withActive,
        _resolve,
      ).loadOwnerDashboard(userId: 'u1', today: today);

      expect(withActive.ownerLogRequests, <String>[
        '3f9a2b41-0000-4000-8000-000000000001',
      ]);
      expect(active.todayLogs, hasLength(1));

      final FakeDashboardDataSource noActive = FakeDashboardDataSource(
        bookings: <Map<String, dynamic>>[bookingRow()],
      );
      await DashboardRepositoryImpl(
        noActive,
        _resolve,
      ).loadOwnerDashboard(userId: 'u1', today: today);
      expect(noActive.ownerLogRequests, isEmpty);
    });

    test('penjaga: dua permintaan cukup, hitungan turunan benar', () async {
      final FakeDashboardDataSource source = FakeDashboardDataSource(
        bookings: <Map<String, dynamic>>[
          bookingRow(
            status: 'CheckedIn',
            checkin: '2026-10-11',
            checkout: '2026-10-12',
            sitter: 's1',
          ),
          bookingRow(
            id: '4a9a2b41-0000-4000-8000-000000000002',
            checkin: '2026-10-12',
            checkout: '2026-10-14',
            sitter: 's1',
          ),
        ],
      );
      final SitterDashboard dashboard = await DashboardRepositoryImpl(
        source,
        _resolve,
      ).loadSitterDashboard(sitterId: 's1', today: today);

      expect(source.sitterLogRequests, 1);
      expect(dashboard.stayingCount, 1);
      expect(dashboard.checkoutTodayCount, 1);
      expect(dashboard.waitingTodayCount, 1);
      expect(dashboard.pendingReportCount, 1);
    });

    test('admin: kapasitas dari unit aktif dan layanan per booking', () async {
      final FakeDashboardDataSource source = FakeDashboardDataSource(
        bookings: <Map<String, dynamic>>[
          bookingRow(status: 'CheckedIn'),
          bookingRow(
            id: '4a9a2b41-0000-4000-8000-000000000002',
            status: 'Pending',
          ),
        ],
        roomRows: <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'room_type': 'Standard',
            'price_per_night': 75000,
          },
        ],
        units: <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'room_id': 1, 'unit_code': 'STD-01'},
          <String, dynamic>{'id': 2, 'room_id': 1, 'unit_code': 'STD-02'},
        ],
        blocks: <Map<String, dynamic>>[
          <String, dynamic>{
            'room_id': 1,
            'blocked_units': 1,
            'purpose': 'Cat ulang',
          },
        ],
        services: <Map<String, dynamic>>[
          <String, dynamic>{
            'booking_id': '3f9a2b41-0000-4000-8000-000000000001',
            'services': <String, dynamic>{'service_name': 'Grooming'},
          },
        ],
      );
      final AdminDashboard dashboard = await DashboardRepositoryImpl(
        source,
        _resolve,
      ).loadAdminDashboard(today: today);

      expect(dashboard.totalUnits, 2);
      expect(dashboard.occupancy.single.availableUnits, 0);
      expect(dashboard.occupancy.single.blockedPurposes, <String>['Cat ulang']);
      expect(dashboard.pendingCount, 1);
      expect(
        dashboard.servicesByBooking['3f9a2b41-0000-4000-8000-000000000001'],
        <String>['Grooming'],
      );
      expect(dashboard.missingReports, hasLength(1));
    });

    test('bukti bayar diminta lewat signed URL', () async {
      final String url = await DashboardRepositoryImpl(
        FakeDashboardDataSource(),
        _resolve,
      ).createPaymentProofUrl('u1/bukti.jpg');
      expect(url, 'signed:u1/bukti.jpg');
    });
  });
}
