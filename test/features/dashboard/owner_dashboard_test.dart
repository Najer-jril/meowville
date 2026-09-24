import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meowville/core/errors/app_exception.dart';
import 'package:meowville/features/auth/domain/entities/user_role.dart';
import 'package:meowville/features/dashboard/domain/entities/booking_status.dart';
import 'package:meowville/features/dashboard/domain/entities/booking_summary.dart';
import 'package:meowville/features/dashboard/domain/entities/owner_dashboard.dart';
import 'package:meowville/features/dashboard/presentation/widgets/filter_segmented_tabs.dart';

import '../../support/app_harness.dart';
import '../auth/presentation/fake_auth_repository.dart';
import 'dashboard_fixtures.dart';

void main() {
  OwnerDashboard compose({
    List<BookingSummary> bookings = const <BookingSummary>[],
    bool withLog = false,
  }) {
    final BookingSummary? active = OwnerDashboard.findActive(bookings);
    return OwnerDashboard.compose(
      bookings: bookings,
      pets: const [miko, luna],
      rooms: const [standardTier, deluxeTier],
      todayLogs: withLog && active != null
          ? <dynamic>[logFor(active)].cast()
          : const [],
      today: today,
    );
  }

  final BookingSummary activeStay = booking(
    id: 'a0000000-0000-4000-8000-000000000001',
    status: BookingStatus.checkedIn,
    checkin: day(-1),
    checkout: day(2),
    unitCode: 'STD-02',
  );

  final BookingSummary upcomingStay = booking(
    id: 'b0000000-0000-4000-8000-000000000002',
    checkin: day(1),
    checkout: day(3),
    pet: luna,
    careInstructions: 'Takut suara vakum.',
  );

  Future<FakeDashboardRepository> open(
    WidgetTester tester,
    FakeDashboardRepository repository, {
    Size size = const Size(393, 852),
  }) async {
    final FakeAuthRepository auth = FakeAuthRepository(
      initialUser: userWithRole(UserRole.petOwner),
    );
    addTearDown(auth.dispose);
    await pumpApp(tester, auth, dashboardRepository: repository, size: size);
    await tester.pumpAndSettle();
    return repository;
  }

  group('tiga keadaan wajib', () {
    testWidgets('memuat: kerangka dengan keterangan, bukan layar kosong', (
      tester,
    ) async {
      final Completer<void> gate = Completer<void>();
      await open(
        tester,
        FakeDashboardRepository(owner: compose(), gate: gate.future),
      );

      expect(find.text('Memuat kabar anabul Anda...'), findsOneWidget);
      expect(find.text('Halo, Rani'), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Halo, Rani'), findsOneWidget);
    });

    testWidgets('galat: menyebut apa yang gagal dan Coba Lagi memuat ulang', (
      tester,
    ) async {
      final FakeDashboardRepository repository = FakeDashboardRepository(
        error: const NetworkException('Tidak ada koneksi.'),
      );
      await open(tester, repository);

      expect(find.text('Dashboard belum bisa dimuat'), findsOneWidget);
      expect(find.text('Tidak ada koneksi.'), findsOneWidget);
      expect(repository.ownerLoads, 1);

      repository
        ..error = null
        ..owner = compose();
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(repository.ownerLoads, 2);
      expect(find.text('Dashboard belum bisa dimuat'), findsNothing);
      expect(find.text('Halo, Rani'), findsOneWidget);
    });

    testWidgets('kosong: menyebut sebabnya dan satu aksi yang mengisinya', (
      tester,
    ) async {
      await open(tester, FakeDashboardRepository(owner: compose()));

      expect(find.text('Kamar masih menunggu anabul'), findsOneWidget);
      expect(find.text('Pilih Tanggal Menginap'), findsOneWidget);
      expect(find.text('Tidak ada data'), findsNothing);
    });
  });

  group('keadaan ditentukan data, bukan ketukan', () {
    testWidgets('tidak ada tab pemilih keadaan', (tester) async {
      await open(
        tester,
        FakeDashboardRepository(owner: compose(bookings: [activeStay])),
      );

      expect(find.byType(FilterSegmentedTabs), findsNothing);
    });

    testWidgets(
      'ada reservasi aktif: hero aktif tampil, bukan kartu mendatang',
      (tester) async {
        await open(
          tester,
          FakeDashboardRepository(
            owner: compose(bookings: [upcomingStay, activeStay], withLog: true),
          ),
        );

        expect(find.text('Miko sedang menginap di Meowville.'), findsOneWidget);
        expect(find.text('Hari ke-2 dari 3'), findsOneWidget);
        expect(find.text('Kamar Standard - STD-02'), findsOneWidget);
        expect(find.text('11 - 14 Okt - 3 malam'), findsOneWidget);
        expect(find.text('Laporan Harian'), findsOneWidget);
        expect(find.text('Detail Reservasi'), findsOneWidget);
        expect(find.text('Kamar masih menunggu anabul'), findsNothing);
      },
    );

    testWidgets('tanpa aktif tetapi ada mendatang: kartu mendatang tampil', (
      tester,
    ) async {
      await open(
        tester,
        FakeDashboardRepository(owner: compose(bookings: [upcomingStay])),
      );

      expect(find.text('Luna check-in besok.'), findsOneWidget);
      expect(find.text('Check-in besok'), findsOneWidget);
      expect(find.text('Dikonfirmasi'), findsOneWidget);
      expect(find.text('Takut suara vakum.'), findsOneWidget);
      expect(find.text('Hari ke-2 dari 3'), findsNothing);
      expect(find.text('Kabar hari ini'), findsNothing);
    });

    testWidgets('banner reservasi baru tampil kecuali pada keadaan kosong', (
      tester,
    ) async {
      await open(tester, FakeDashboardRepository(owner: compose()));
      expect(find.text('Buat Reservasi Baru'), findsNothing);

      await open(
        tester,
        FakeDashboardRepository(owner: compose(bookings: [upcomingStay])),
      );
      expect(find.text('Buat Reservasi Baru'), findsOneWidget);
    });
  });

  group('cuplikan laporan hari ini', () {
    testWidgets('menampilkan mood, jam makan, catatan, penulis, dan tautan', (
      tester,
    ) async {
      await open(
        tester,
        FakeDashboardRepository(
          owner: compose(bookings: [activeStay], withLog: true),
        ),
      );
      await tester.ensureVisible(find.text('Kabar hari ini'));
      await tester.pumpAndSettle();

      expect(find.text('Ceria'), findsOneWidget);
      expect(find.text('Makan 08:30'), findsOneWidget);
      expect(find.text('"Makan lahap dan main bola."'), findsOneWidget);
      expect(find.text('Gilang - 5 jam lalu'), findsOneWidget);
      expect(find.text('Buka semua laporan (1 hari ini)'), findsOneWidget);
    });

    testWidgets('belum ada log: seksi tetap tampil dengan keadaan kosongnya', (
      tester,
    ) async {
      await open(
        tester,
        FakeDashboardRepository(owner: compose(bookings: [activeStay])),
      );
      await tester.ensureVisible(find.text('Kabar hari ini'));
      await tester.pumpAndSettle();

      expect(find.text('Kabar hari ini'), findsOneWidget);
      expect(
        find.text('Penjaga belum menulis kabar hari ini.'),
        findsOneWidget,
      );
    });
  });

  testWidgets('lencana Sedang Menginap muncul di kartu kucing yang menginap', (
    tester,
  ) async {
    await open(
      tester,
      FakeDashboardRepository(owner: compose(bookings: [activeStay])),
    );
    await tester.ensureVisible(find.text('Anabul tersayang'));
    await tester.pumpAndSettle();

    expect(find.text('Luna'), findsOneWidget);
    expect(find.text('Sedang Menginap'), findsNWidgets(2));
  });

  testWidgets('tipe kamar menampilkan harga dan layanan sebagai daftar', (
    tester,
  ) async {
    await open(tester, FakeDashboardRepository(owner: compose()));
    await tester.ensureVisible(find.text('Tipe kamar'));
    await tester.pumpAndSettle();

    expect(find.text('Rp 75.000 / malam'), findsOneWidget);
    expect(find.text('Makan dua kali'), findsOneWidget);
    expect(find.text('Rp 120.000 / malam'), findsOneWidget);
  });

  group('interaksi', () {
    testWidgets('Laporan Harian membuka rute laporan pemilik', (tester) async {
      await open(
        tester,
        FakeDashboardRepository(owner: compose(bookings: [activeStay])),
      );

      await tester.tap(find.text('Laporan Harian'));
      await tester.pumpAndSettle();

      expect(find.text('Belum dibangun'), findsOneWidget);
      expect(
        find.text(
          'Baca kabar harian dari penjaga untuk kucing yang sedang menginap.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Tambah Kucing membuka rute Kucingku', (tester) async {
      await open(tester, FakeDashboardRepository(owner: compose()));
      await tester.ensureVisible(find.text('Tambah Kucing'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tambah Kucing'));
      await tester.pumpAndSettle();

      expect(
        find.text('Lihat dan ubah data kucing yang Anda titipkan.'),
        findsOneWidget,
      );
    });

    testWidgets('Pilih Tanggal Menginap membuka rute reservasi', (
      tester,
    ) async {
      await open(
        tester,
        FakeDashboardRepository(
          owner: OwnerDashboard.compose(
            bookings: const [],
            pets: const [],
            rooms: const [],
            todayLogs: const [],
            today: today,
          ),
        ),
      );

      await tester.tap(find.text('Pilih Tanggal Menginap'));
      await tester.pumpAndSettle();

      expect(
        find.text('Buat reservasi baru dan lihat semua reservasi Anda.'),
        findsOneWidget,
      );
    });

    testWidgets('tarik untuk menyegarkan memuat ulang data', (tester) async {
      final FakeDashboardRepository repository = FakeDashboardRepository(
        owner: compose(bookings: [activeStay]),
      );
      await open(tester, repository);
      expect(repository.ownerLoads, 1);

      await tester.fling(
        find.byType(SingleChildScrollView).first,
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(repository.ownerLoads, 2);
    });
  });

  testWidgets('tidak ada luapan mendatar pada 320 px dengan data penuh', (
    tester,
  ) async {
    await open(
      tester,
      FakeDashboardRepository(
        owner: compose(bookings: [activeStay, upcomingStay], withLog: true),
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
