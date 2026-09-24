import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meowville/core/errors/app_exception.dart';
import 'package:meowville/features/auth/domain/entities/user_role.dart';
import 'package:meowville/features/dashboard/domain/entities/booking_status.dart';
import 'package:meowville/features/dashboard/domain/entities/booking_summary.dart';
import 'package:meowville/features/dashboard/domain/entities/daily_log_entry.dart';
import 'package:meowville/features/dashboard/domain/entities/pet_summary.dart';
import 'package:meowville/features/dashboard/domain/entities/sitter_dashboard.dart';

import '../../support/app_harness.dart';
import '../auth/presentation/fake_auth_repository.dart';
import 'dashboard_fixtures.dart';

void main() {
  final BookingSummary arrivedToday = booking(
    id: 'a0000000-0000-4000-8000-000000000001',
    status: BookingStatus.checkedIn,
    checkin: day(-1),
    checkout: day(0),
    unitCode: 'STD-01',
    assignedSitterId: 's1',
    careInstructions: 'Obat tetes mata pagi hari.',
  );
  final BookingSummary stayingLong = booking(
    id: 'b0000000-0000-4000-8000-000000000002',
    status: BookingStatus.checkedIn,
    checkin: day(-2),
    checkout: day(3),
    pet: luna,
    unitCode: 'STD-02',
    assignedSitterId: 's1',
    ownerName: 'Budi Santoso',
  );
  final BookingSummary waitingToday = booking(
    id: 'c0000000-0000-4000-8000-000000000003',
    checkin: day(0),
    checkout: day(2),
    assignedSitterId: 's1',
    pet: const PetSummary(id: 'pet-3', name: 'Tigra', breed: 'Bengal'),
  );

  SitterDashboard compose(
    List<BookingSummary> guests, {
    List<DailyLogEntry> logs = const <DailyLogEntry>[],
  }) => SitterDashboard.compose(guests: guests, todayLogs: logs, today: today);

  Future<FakeDashboardRepository> open(
    WidgetTester tester,
    FakeDashboardRepository repository, {
    Size size = const Size(393, 852),
  }) async {
    final FakeAuthRepository auth = FakeAuthRepository(
      initialUser: userWithRole(UserRole.petSitter, name: 'Gilang Pratama'),
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
        FakeDashboardRepository(sitter: compose(const []), gate: gate.future),
      );

      expect(find.text('Memuat tugas hari ini...'), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Halo, Gilang'), findsOneWidget);
    });

    testWidgets('galat: pesan dan Coba Lagi yang benar-benar memuat ulang', (
      tester,
    ) async {
      final FakeDashboardRepository repository = FakeDashboardRepository(
        error: const UnexpectedException('Server sedang sibuk.'),
      );
      await open(tester, repository);

      expect(find.text('Server sedang sibuk.'), findsOneWidget);

      repository
        ..error = null
        ..sitter = compose(const []);
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(repository.sitterLoads, 2);
      expect(find.text('Halo, Gilang'), findsOneWidget);
    });

    testWidgets('kosong: penjaga belum punya penugasan', (tester) async {
      await open(tester, FakeDashboardRepository(sitter: compose(const [])));

      expect(
        find.text('Belum ada kucing yang ditugaskan untuk hari ini.'),
        findsOneWidget,
      );
      expect(
        find.text('Belum ada tamu yang ditugaskan kepada Anda.'),
        findsOneWidget,
      );
      expect(find.text('Mulai Catat Laporan'), findsNothing);
    });
  });

  group('angka dan tugas turunan dari data', () {
    testWidgets('kartu ringkasan dan sapaan sesuai penugasan', (tester) async {
      await open(
        tester,
        FakeDashboardRepository(
          sitter: compose(
            <BookingSummary>[arrivedToday, stayingLong, waitingToday],
            logs: <DailyLogEntry>[logFor(arrivedToday)],
          ),
        ),
      );

      expect(
        find.text('3 anabul jadi tanggung jawab Anda hari ini.'),
        findsOneWidget,
      );
      expect(find.text('Tamu Menginap'), findsOneWidget);
      expect(find.text('Laporan Tertunda'), findsOneWidget);
      expect(find.text('0 sudah tiba, 1 menunggu'), findsOneWidget);
    });

    testWidgets('tugas berurutan dan check-in/out tidak punya tombol mati', (
      tester,
    ) async {
      await open(
        tester,
        FakeDashboardRepository(
          sitter: compose(<BookingSummary>[
            stayingLong,
            arrivedToday,
            waitingToday,
          ]),
        ),
      );
      await scrollTo(tester, find.text('Prioritas tugas'));

      final double checkIn = tester.getTopLeft(find.text('Siap check-in')).dy;
      final double checkOut = tester
          .getTopLeft(find.text('Check-out hari ini'))
          .dy;
      final double report = tester
          .getTopLeft(find.text('Laporan belum ditulis').first)
          .dy;
      expect(checkIn, lessThan(checkOut));
      expect(checkOut, lessThan(report));

      expect(find.text('Tandai Check-in'), findsNothing);
      expect(find.text('Selesaikan Check-out'), findsNothing);
    });

    testWidgets('tanpa tugas tertunda: pesan semua laporan sudah masuk', (
      tester,
    ) async {
      await open(
        tester,
        FakeDashboardRepository(
          sitter: compose(
            <BookingSummary>[stayingLong],
            logs: <DailyLogEntry>[logFor(stayingLong)],
          ),
        ),
      );
      await scrollTo(tester, find.text('Prioritas tugas'));

      expect(find.text('Tidak ada tugas tertunda.'), findsOneWidget);
      expect(find.text('Semua laporan hari ini sudah masuk.'), findsOneWidget);
    });
  });

  group('kartu Catat Laporan', () {
    testWidgets('chip nama kucing yang belum dicatat membuka formulir', (
      tester,
    ) async {
      await open(
        tester,
        FakeDashboardRepository(
          sitter: compose(
            <BookingSummary>[arrivedToday, stayingLong],
            logs: <DailyLogEntry>[logFor(arrivedToday)],
          ),
        ),
      );
      await scrollTo(tester, find.text('Catat laporan hari ini'));

      final Finder chip = find.bySemanticsLabel('Catat laporan untuk Luna');
      await tester.tap(chip);
      await tester.pumpAndSettle();

      expect(
        find.text('Tulis laporan harian untuk kucing yang menginap.'),
        findsOneWidget,
      );
    });

    testWidgets('semua sudah dicatat: kartu menyebutnya tanpa chip', (
      tester,
    ) async {
      await open(
        tester,
        FakeDashboardRepository(
          sitter: compose(
            <BookingSummary>[stayingLong],
            logs: <DailyLogEntry>[logFor(stayingLong)],
          ),
        ),
      );
      await scrollTo(tester, find.text('Catat laporan hari ini'));

      expect(
        find.text('Semua tamu menginap sudah punya laporan hari ini.'),
        findsOneWidget,
      );
    });
  });

  group('tamu menginap hari ini', () {
    Future<FakeDashboardRepository> openWithGuests(WidgetTester tester) {
      return open(
        tester,
        FakeDashboardRepository(
          sitter: compose(
            <BookingSummary>[arrivedToday, stayingLong],
            logs: <DailyLogEntry>[logFor(arrivedToday)],
          ),
        ),
      );
    }

    testWidgets('tab penyaring mengubah jumlah kartu tanpa permintaan baru', (
      tester,
    ) async {
      final FakeDashboardRepository repository = await openWithGuests(tester);
      await scrollTo(tester, find.text('Tamu menginap hari ini'));

      expect(find.text('Semua (2)'), findsOneWidget);
      expect(find.text('Belum ada laporan (1)'), findsOneWidget);
      expect(find.text('Sudah lengkap (1)'), findsOneWidget);
      expect(find.text('Input Laporan'), findsOneWidget);
      expect(find.text('Lihat Log'), findsOneWidget);

      await tester.tap(find.text('Belum ada laporan (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Input Laporan'), findsOneWidget);
      expect(find.text('Lihat Log'), findsNothing);

      await tester.tap(find.text('Sudah lengkap (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Input Laporan'), findsNothing);
      expect(find.text('Lihat Log'), findsOneWidget);

      expect(repository.sitterLoads, 1);
    });

    testWidgets(
      'kartu tamu memuat pemilik, kamar, progres, dan pesan pemilik',
      (tester) async {
        await openWithGuests(tester);
        await scrollTo(tester, find.text('Tamu menginap hari ini'));

        expect(find.text('Pemilik: Budi Santoso'), findsOneWidget);
        expect(find.text('Hari ke-3 dari 5'), findsOneWidget);
        expect(find.text('Persia - Kamar Standard - STD-02'), findsOneWidget);
        expect(find.text('Laporan sudah masuk'), findsOneWidget);
        expect(find.text('Belum ada laporan'), findsOneWidget);
        await scrollTo(tester, find.text('Obat tetes mata pagi hari.'));
        expect(find.text('Pesan pemilik'), findsOneWidget);
      },
    );

    testWidgets('Input Laporan dan Lihat Log menuju rute yang ada', (
      tester,
    ) async {
      await openWithGuests(tester);
      await scrollTo(tester, find.text('Lihat Log'));
      await tester.tap(find.text('Lihat Log'));
      await tester.pumpAndSettle();

      expect(
        find.text('Laporan yang sudah Anda tulis sebelumnya.'),
        findsOneWidget,
      );
    });

    testWidgets('tanpa tamu menginap: keadaan kosong dengan sebab', (
      tester,
    ) async {
      await open(
        tester,
        FakeDashboardRepository(
          sitter: compose(<BookingSummary>[waitingToday]),
        ),
      );
      await scrollTo(tester, find.text('Tamu menginap hari ini'));

      expect(find.text('Belum ada tamu yang sedang menginap.'), findsOneWidget);
    });
  });

  testWidgets('tidak ada luapan mendatar pada 320 px, teks normal dan besar', (
    tester,
  ) async {
    await open(
      tester,
      FakeDashboardRepository(
        sitter: compose(
          <BookingSummary>[arrivedToday, stayingLong, waitingToday],
          logs: <DailyLogEntry>[logFor(arrivedToday)],
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
