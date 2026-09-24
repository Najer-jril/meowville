import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meowville/core/errors/app_exception.dart';
import 'package:meowville/features/admin_rooms/presentation/screens/admin_rooms_screen.dart';
import 'package:meowville/features/auth/domain/entities/user_role.dart';
import 'package:meowville/features/dashboard/domain/entities/admin_dashboard.dart';
import 'package:meowville/features/dashboard/domain/entities/booking_status.dart';
import 'package:meowville/features/dashboard/domain/entities/booking_summary.dart';
import 'package:meowville/features/dashboard/domain/entities/daily_log_entry.dart';
import 'package:meowville/features/dashboard/domain/entities/pet_summary.dart';

import '../../support/app_harness.dart';
import '../auth/presentation/fake_auth_repository.dart';
import 'dashboard_fixtures.dart';

void main() {
  const List<RoomUnitInfo> units = <RoomUnitInfo>[
    RoomUnitInfo(id: 1, roomId: 1, unitCode: 'STD-01'),
    RoomUnitInfo(id: 2, roomId: 1, unitCode: 'STD-02'),
    RoomUnitInfo(id: 3, roomId: 1, unitCode: 'STD-03'),
    RoomUnitInfo(id: 4, roomId: 1, unitCode: 'STD-04'),
    RoomUnitInfo(id: 5, roomId: 2, unitCode: 'DLX-01'),
    RoomUnitInfo(id: 6, roomId: 2, unitCode: 'DLX-02'),
  ];

  final BookingSummary olderPending = booking(
    id: '3f9a2b41-0000-4000-8000-000000000001',
    status: BookingStatus.pending,
    createdAt: DateTime(2026, 10, 9, 10),
    paymentProofPath: 'u1/bukti.jpg',
    careInstructions: 'Butuh selimut.',
  );
  final BookingSummary newerPending = booking(
    id: '4a9a2b41-0000-4000-8000-000000000002',
    status: BookingStatus.pending,
    createdAt: DateTime(2026, 10, 12, 8),
    pet: luna,
    tier: deluxeTier,
    ownerName: 'Budi Santoso',
    totalPrice: 480000,
  );
  final BookingSummary staying = booking(
    id: '5b9a2b41-0000-4000-8000-000000000003',
    status: BookingStatus.checkedIn,
    checkin: day(-1),
    checkout: day(2),
    unitCode: 'STD-01',
    pet: const PetSummary(id: 'pet-3', name: 'Tigra', breed: 'Bengal'),
  );

  AdminDashboard compose({
    List<BookingSummary> live = const <BookingSummary>[],
    List<BookingSummary>? recent,
    List<RoomBlockInfo> blocks = const <RoomBlockInfo>[],
    List<DailyLogEntry> logs = const <DailyLogEntry>[],
    Map<String, List<String>> services = const <String, List<String>>{},
  }) {
    return AdminDashboard.compose(
      liveBookings: live,
      recent: recent ?? live,
      rooms: const [standardTier, deluxeTier],
      units: units,
      blocks: blocks,
      todayLogs: logs,
      servicesByBooking: services,
      today: today,
    );
  }

  Future<FakeDashboardRepository> open(
    WidgetTester tester,
    FakeDashboardRepository repository, {
    Size size = const Size(393, 852),
  }) async {
    final FakeAuthRepository auth = FakeAuthRepository(
      initialUser: userWithRole(UserRole.admin, name: 'Dewi Anggraini'),
    );
    addTearDown(auth.dispose);
    await pumpApp(tester, auth, dashboardRepository: repository, size: size);
    await tester.pumpAndSettle();
    return repository;
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  group('tiga keadaan wajib', () {
    testWidgets('memuat: kerangka dengan keterangan', (tester) async {
      final Completer<void> gate = Completer<void>();
      await open(
        tester,
        FakeDashboardRepository(admin: compose(), gate: gate.future),
      );

      expect(find.text('Memuat ringkasan hari ini...'), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Halo, Dewi'), findsOneWidget);
    });

    testWidgets('galat: pesan dan Coba Lagi yang benar-benar memuat ulang', (
      tester,
    ) async {
      final FakeDashboardRepository repository = FakeDashboardRepository(
        error: const UnauthorizedException('Akun ini tidak berhak.'),
      );
      await open(tester, repository);

      expect(find.text('Akun ini tidak berhak.'), findsOneWidget);

      repository
        ..error = null
        ..admin = compose();
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(repository.adminLoads, 2);
      expect(find.text('Halo, Dewi'), findsOneWidget);
    });

    testWidgets('kosong: setiap seksi menyebut sebabnya', (tester) async {
      await open(tester, FakeDashboardRepository(admin: compose()));

      expect(
        find.text('Tidak ada reservasi yang menunggu persetujuan.'),
        findsOneWidget,
      );
      await scrollTo(tester, find.text('Laporan harian belum masuk'));
      expect(find.text('Belum ada tamu yang menginap.'), findsOneWidget);
      await scrollTo(tester, find.text('Reservasi terbaru'));
      expect(find.text('Belum ada reservasi.'), findsOneWidget);
    });
  });

  group('perlu keputusan Anda', () {
    testWidgets(
      'daftar tunggu: terlama di atas, dengan kode delapan karakter',
      (tester) async {
        await open(
          tester,
          FakeDashboardRepository(
            admin: compose(live: <BookingSummary>[newerPending, olderPending]),
          ),
        );

        expect(find.text('#3f9a2b41'), findsOneWidget);
        expect(find.text('#4a9a2b41'), findsOneWidget);
        final double older = tester.getTopLeft(find.text('#3f9a2b41')).dy;
        final double newer = tester.getTopLeft(find.text('#4a9a2b41')).dy;
        expect(older, lessThan(newer));
        expect(
          find.textContaining('2 reservasi menunggu keputusan'),
          findsOneWidget,
        );
      },
    );

    testWidgets('kartu memuat pemilik, total, waktu tunggu, dan pesan', (
      tester,
    ) async {
      await open(
        tester,
        FakeDashboardRepository(admin: compose(live: [olderPending])),
      );

      expect(find.text('Pemilik: Rani Pratama'), findsOneWidget);
      expect(find.text('Total Rp 225.000'), findsOneWidget);
      expect(find.text('Diajukan 3 hari lalu'), findsOneWidget);
      expect(find.text('Butuh selimut.'), findsOneWidget);
    });

    testWidgets('tanpa bukti bayar: label ketiadaan, bukan tautan kosong', (
      tester,
    ) async {
      await open(
        tester,
        FakeDashboardRepository(admin: compose(live: [newerPending])),
      );

      expect(find.text('Bukti bayar belum diunggah'), findsOneWidget);
      expect(find.text('Lihat Bukti'), findsNothing);
    });

    testWidgets('Lihat Bukti meminta signed URL lalu membuka dialog', (
      tester,
    ) async {
      final FakeDashboardRepository repository = FakeDashboardRepository(
        admin: compose(live: [olderPending]),
      );
      await open(tester, repository);

      await tester.tap(find.text('Lihat Bukti'));
      await tester.pump();
      await tester.pump();

      expect(repository.proofRequests, <String>['u1/bukti.jpg']);
      expect(find.text('Bukti bayar Miko'), findsOneWidget);
      expect(find.text('Tutup'), findsOneWidget);

      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
      expect(find.text('Bukti bayar Miko'), findsNothing);
    });
  });

  group('okupansi dan ringkasan', () {
    testWidgets('bar tersegmentasi, rasio, persen, dan unit ditutup', (
      tester,
    ) async {
      await open(
        tester,
        FakeDashboardRepository(
          admin: compose(
            live: <BookingSummary>[
              staying,
              booking(
                id: '6c9a2b41-0000-4000-8000-000000000004',
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
          ),
        ),
      );
      await scrollTo(tester, find.text('Okupansi kamar'));

      expect(find.text('2 / 4'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(
        find.text('1 unit tersedia - 1 unit ditutup: Pembersihan menyeluruh'),
        findsOneWidget,
      );
      expect(find.text('0 / 2'), findsOneWidget);
    });

    testWidgets('ringkasan check-in, aktif menginap, dan kamar kosong', (
      tester,
    ) async {
      await open(
        tester,
        FakeDashboardRepository(
          admin: compose(
            live: <BookingSummary>[
              staying,
              booking(
                id: '6c9a2b41-0000-4000-8000-000000000004',
                status: BookingStatus.confirmed,
              ),
            ],
          ),
        ),
      );
      await scrollTo(tester, find.text('Check-in Hari Ini'));

      expect(find.text('0 sudah tiba, 1 menunggu'), findsOneWidget);
      expect(find.text('Aktif Menginap'), findsOneWidget);
      expect(find.text('33% kapasitas'), findsOneWidget);
      expect(find.text('Standard 2, Deluxe 2'), findsOneWidget);
    });
  });

  group('laporan harian belum masuk', () {
    testWidgets('menyebut jumlah, nama, dan penjaga yang belum ditugaskan', (
      tester,
    ) async {
      await open(
        tester,
        FakeDashboardRepository(
          admin: compose(live: <BookingSummary>[staying]),
        ),
      );
      await scrollTo(tester, find.text('Laporan harian belum masuk'));

      expect(find.text('1 tamu belum ada laporan hari ini'), findsOneWidget);
      expect(find.text('Tigra'), findsWidgets);
      expect(find.text('Belum ada penjaga'), findsWidgets);
    });

    testWidgets('semua tercatat: satu baris konfirmasi, bukan hilang', (
      tester,
    ) async {
      await open(
        tester,
        FakeDashboardRepository(
          admin: compose(
            live: <BookingSummary>[staying],
            logs: <DailyLogEntry>[logFor(staying)],
          ),
        ),
      );
      await scrollTo(tester, find.text('Laporan harian belum masuk'));

      expect(find.text('Semua laporan hari ini sudah masuk.'), findsOneWidget);
    });

    testWidgets('Buka Daftar Penjaga menuju daftar akun staf', (tester) async {
      await open(
        tester,
        FakeDashboardRepository(
          admin: compose(live: <BookingSummary>[staying]),
        ),
      );
      await scrollTo(tester, find.text('Buka Daftar Penjaga'));
      await tester.tap(find.text('Buka Daftar Penjaga'));
      await tester.pumpAndSettle();

      expect(find.text('Akun staf'), findsOneWidget);
    });
  });

  group('aksi cepat dan reservasi terbaru', () {
    testWidgets('lencana Reservasi berisi jumlah Pending dan tombolnya jalan', (
      tester,
    ) async {
      await open(
        tester,
        FakeDashboardRepository(
          admin: compose(live: <BookingSummary>[olderPending, newerPending]),
        ),
      );
      await scrollTo(tester, find.text('Aksi cepat'));

      expect(find.bySemanticsLabel('Reservasi, 2 menunggu'), findsOneWidget);

      await tester.tap(find.text('Kamar').first);
      await tester.pumpAndSettle();
      expect(find.byType(AdminRoomsScreen), findsOneWidget);
    });

    testWidgets('reservasi terbaru memuat status, unit, dan layanan tambahan', (
      tester,
    ) async {
      await open(
        tester,
        FakeDashboardRepository(
          admin: compose(
            live: <BookingSummary>[staying],
            services: <String, List<String>>{
              staying.id: <String>['Grooming'],
            },
          ),
        ),
      );
      await scrollTo(tester, find.text('Reservasi terbaru'));

      expect(find.text('Sedang Menginap'), findsOneWidget);
      expect(find.text('Grooming'), findsOneWidget);
      expect(find.text('Lihat Semua'), findsOneWidget);
    });
  });

  group('tab penyaring', () {
    testWidgets('Perlu Respon menyembunyikan okupansi, menampilkan antrean', (
      tester,
    ) async {
      final FakeDashboardRepository repository = await open(
        tester,
        FakeDashboardRepository(
          admin: compose(live: <BookingSummary>[olderPending, staying]),
        ),
      );
      expect(find.text('Perlu Respon (1)'), findsOneWidget);

      await tester.tap(find.text('Perlu Respon (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Perlu keputusan Anda'), findsOneWidget);
      expect(find.text('Okupansi kamar'), findsNothing);
      expect(find.text('Reservasi terbaru'), findsNothing);
      expect(repository.adminLoads, 1);
    });

    testWidgets('Hari Ini menyembunyikan antrean persetujuan', (tester) async {
      await open(
        tester,
        FakeDashboardRepository(admin: compose(live: [olderPending])),
      );

      await tester.tap(find.text('Hari Ini'));
      await tester.pumpAndSettle();

      expect(find.text('Perlu keputusan Anda'), findsNothing);
      expect(find.text('Okupansi kamar'), findsOneWidget);
    });
  });

  testWidgets('tidak ada luapan mendatar pada 320 px, teks normal dan besar', (
    tester,
  ) async {
    await open(
      tester,
      FakeDashboardRepository(
        admin: compose(
          live: <BookingSummary>[olderPending, newerPending, staying],
          blocks: const <RoomBlockInfo>[
            RoomBlockInfo(
              roomId: 1,
              blockedUnits: 1,
              purpose: 'Pembersihan menyeluruh',
            ),
          ],
          services: <String, List<String>>{
            staying.id: <String>['Grooming', 'Antar jemput'],
          },
        ),
      ),
      size: const Size(320, 640),
    );
    expect(tester.takeException(), isNull);

    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
