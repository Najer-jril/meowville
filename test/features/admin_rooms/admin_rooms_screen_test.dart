import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meowville/core/errors/app_exception.dart';
import 'package:meowville/features/admin_rooms/presentation/widgets/room_cards.dart';
import 'package:meowville/features/auth/domain/entities/user_role.dart';

import '../../support/app_harness.dart';
import '../auth/presentation/fake_auth_repository.dart';
import 'fake_admin_room_repository.dart';

void main() {
  const String listRoute = '/admin/kamar';

  FakeAdminRoomDataSource seeded() => FakeAdminRoomDataSource(
    rooms: <Map<String, dynamic>>[
      roomRow(1, 'Standard', price: 95000),
      roomRow(2, 'Deluxe'),
    ],
    units: <Map<String, dynamic>>[
      unitRow(1, 1, 'STD-01'),
      unitRow(2, 1, 'STD-02'),
      unitRow(3, 2, 'DLX-01'),
      unitRow(4, 2, 'DLX-02'),
      unitRow(5, 2, 'DLX-03'),
    ],
    bookings: <Map<String, dynamic>>[bookingRow('b1', 2, unitId: 3)],
    blocks: <Map<String, dynamic>>[
      blockRow('k1', 2, 'Deluxe', purpose: 'Perbaikan AC'),
    ],
  );

  Future<FakeAdminRoomDataSource> open(
    WidgetTester tester, {
    String location = listRoute,
    FakeAdminRoomDataSource? source,
    Size size = const Size(393, 852),
  }) async {
    final FakeAuthRepository auth = FakeAuthRepository(
      initialUser: userWithRole(UserRole.admin),
    );
    addTearDown(auth.dispose);
    final FakeAdminRoomDataSource data = source ?? seeded();
    await pumpApp(
      tester,
      auth,
      adminRoomRepository: FakeAdminRoomRepository(source: data),
      location: location,
      size: size,
    );
    await tester.pumpAndSettle();
    return data;
  }

  group('tab tipe kamar', () {
    testWidgets('keadaan memuat menyebut apa yang dimuat', (tester) async {
      final Completer<void> gate = Completer<void>();
      final FakeAuthRepository auth = FakeAuthRepository(
        initialUser: userWithRole(UserRole.admin),
      );
      addTearDown(auth.dispose);
      await pumpApp(
        tester,
        auth,
        adminRoomRepository: FakeAdminRoomRepository(
          source: FakeAdminRoomDataSource(gate: gate.future),
        ),
        location: listRoute,
      );

      expect(find.text('Memuat data kamar...'), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('galat memuat menampilkan pesan dan Coba Lagi', (tester) async {
      await open(
        tester,
        source: FakeAdminRoomDataSource(
          loadError: const NetworkException('Server tidak terjangkau.'),
        ),
      );

      expect(find.text('Data kamar belum bisa dimuat'), findsOneWidget);
      expect(find.text('Server tidak terjangkau.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('kartu menampilkan tarif dan ketersediaan hari ini', (
      tester,
    ) async {
      await open(tester);

      expect(find.byType(RoomTierCard), findsNWidgets(2));
      expect(find.text('Rp 95.000 / malam'), findsOneWidget);
      // Deluxe: 3 unit, 1 terisi, 1 ditutup.
      expect(find.text('1 / 3 unit'), findsOneWidget);
      expect(find.text('1 terisi, 1 ditutup (Perbaikan AC)'), findsOneWidget);
      expect(find.text('Tambah tipe kamar'), findsOneWidget);
    });

    testWidgets('tanpa tier: keadaan kosong dengan aksi tambah', (
      tester,
    ) async {
      await open(tester, source: FakeAdminRoomDataSource());

      expect(find.text('Belum ada tipe kamar'), findsOneWidget);
      await tapVisible(tester, find.text('Tambah tipe kamar'));
      await tester.pumpAndSettle();
      expect(
        find.text('Satu tier per jenis. Unit baru diberi kode urut otomatis.'),
        findsOneWidget,
      );
    });

    testWidgets('ubah tarif dan unit lalu kembali ke daftar', (tester) async {
      final FakeAdminRoomDataSource data = await open(tester);

      await tester.tap(find.text('Rp 95.000 / malam'));
      await tester.pumpAndSettle();
      expect(find.text('Ubah kamar Standard'), findsOneWidget);

      await tester.enterText(
        find.bySemanticsLabel('Harga per malam dalam rupiah'),
        '120000',
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byTooltip('Tambah unit'));
      await tapVisible(tester, find.text('Simpan perubahan'));
      await tester.pumpAndSettle();

      expect(find.text('Perubahan Standard tersimpan.'), findsOneWidget);
      expect(find.text('Rp 120.000 / malam'), findsOneWidget);
      expect(find.text('3 / 3 unit'), findsOneWidget);
      expect(
        data.unitRows.where((Map<String, dynamic> u) => u['room_id'] == 1),
        hasLength(3),
      );
    });

    testWidgets('tombol kurangi mati di batas reservasi aktif', (tester) async {
      await open(tester, location: '$listRoute/2');

      expect(find.text('Minimal 1, jumlah reservasi aktif'), findsNothing);
      for (int i = 0; i < 2; i++) {
        await tapVisible(tester, find.byTooltip('Kurangi unit'));
      }
      // Dari 3 turun ke 1; tombol kini mati.
      expect(
        find.descendant(
          of: find.bySemanticsLabel('Jumlah unit aktif'),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('paket kosong menampilkan galat di kolomnya', (tester) async {
      await open(tester, location: '$listRoute/1');

      await tester.enterText(find.bySemanticsLabel('Paket layanan bawaan'), '');
      await tapVisible(tester, find.text('Simpan perubahan'));

      expect(find.text('Isi paket layanan bawaan tier ini.'), findsOneWidget);
    });

    testWidgets('tambah tier baru dari tipe yang belum ada', (tester) async {
      final FakeAdminRoomDataSource data = await open(tester);

      await tapVisible(tester, find.text('Tambah tipe kamar'));
      await tester.pumpAndSettle();
      // Hanya Suite yang belum ada, jadi langsung terpilih.
      await tester.enterText(
        find.bySemanticsLabel('Paket layanan bawaan'),
        'CCTV, grooming',
      );
      await tester.enterText(
        find.bySemanticsLabel('Harga per malam dalam rupiah'),
        '250000',
      );
      // Judul layar juga berbunyi sama; tombolnya elemen terakhir.
      await tapVisible(tester, find.bySemanticsLabel('Tambah tipe kamar').last);
      await tester.pumpAndSettle();

      expect(find.text('Tipe Suite ditambahkan.'), findsOneWidget);
      expect(find.text('Rp 250.000 / malam'), findsOneWidget);
      expect(
        data.unitRows.where(
          (Map<String, dynamic> u) => u['unit_code'] == 'STE-01',
        ),
        hasLength(1),
      );
      // Ketiga tier ada: tombol tambah hilang.
      expect(find.text('Tambah tipe kamar'), findsNothing);
    });

    testWidgets('hapus tier yang punya reservasi ditolak dengan alasan', (
      tester,
    ) async {
      await open(tester, location: '$listRoute/2');

      await tapVisible(tester, find.text('Hapus tipe Deluxe'));
      await tester.tap(find.text('Ya, hapus tipe'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('sudah punya riwayat reservasi'),
        findsWidgets,
      );
      expect(find.text('Ubah kamar Deluxe'), findsOneWidget);
    });

    testWidgets('hapus tier tanpa reservasi kembali ke daftar', (tester) async {
      final FakeAdminRoomDataSource data = await open(
        tester,
        location: '$listRoute/1',
      );

      await tapVisible(tester, find.text('Hapus tipe Standard'));
      await tester.tap(find.text('Ya, hapus tipe'));
      await tester.pumpAndSettle();

      expect(data.roomRows.map((Map<String, dynamic> r) => r['id']), <int>[2]);
      expect(find.text('Tipe Standard dihapus.'), findsOneWidget);
    });

    testWidgets('id tier yang tidak ada', (tester) async {
      await open(tester, location: '$listRoute/99');
      expect(find.text('Tipe kamar tidak ditemukan'), findsOneWidget);
    });

    testWidgets('tidak meluap pada 320 px', (tester) async {
      await open(tester, size: const Size(320, 640));
      expect(tester.takeException(), isNull);
      await open(tester, location: '$listRoute/2', size: const Size(320, 640));
      expect(tester.takeException(), isNull);
    });
  });

  group('tab blokir unit', () {
    Future<void> openBlocks(WidgetTester tester) async {
      await tester.tap(find.bySemanticsLabel(RegExp('^Blokir unit')).first);
      await tester.pumpAndSettle();
    }

    testWidgets('daftar blokir dengan keperluan dan status berlangsung', (
      tester,
    ) async {
      await open(tester);
      await openBlocks(tester);

      expect(find.byType(RoomBlockCard), findsOneWidget);
      expect(find.text('Keperluan: Perbaikan AC'), findsOneWidget);
      expect(find.text('Berlangsung'), findsOneWidget);
    });

    testWidgets('tanpa blokir: keadaan kosong', (tester) async {
      final FakeAdminRoomDataSource data = seeded()..blockRows.clear();
      await open(tester, source: data);
      await openBlocks(tester);

      expect(find.text('Tidak ada unit yang ditutup'), findsOneWidget);
    });

    testWidgets('membuat blokir lewat sheet', (tester) async {
      final FakeAdminRoomDataSource data = await open(tester);
      await openBlocks(tester);

      await tester.tap(find.bySemanticsLabel('Blokir unit').last);
      await tester.pumpAndSettle();
      expect(find.text('Blokir unit kamar'), findsOneWidget);

      // Tanpa isian, galat per kolom muncul.
      await tapVisible(tester, find.text('Simpan blokir'));
      expect(find.text('Pilih tipe kamar.'), findsOneWidget);
      expect(find.text('Pilih tanggal mulai dan selesai.'), findsOneWidget);

      await tapVisible(tester, find.bySemanticsLabel('Standard'));
      await tapVisible(
        tester,
        find.bySemanticsLabel(RegExp('^Tanggal mulai,')),
      );
      await tester.tap(find.text('15'));
      await tester.tap(find.text('Pilih'));
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.bySemanticsLabel(RegExp('^Tanggal selesai,')),
      );
      await tester.tap(find.text('16'));
      await tester.tap(find.text('Pilih'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.bySemanticsLabel('Keperluan blokir'),
        'Cat ulang',
      );
      await tapVisible(tester, find.text('Simpan blokir'));
      await tester.pumpAndSettle();

      expect(data.insertedBlocks.single['date_start'], '2026-10-15');
      expect(data.insertedBlocks.single['date_end'], '2026-10-16');
      expect(
        data.insertedBlocks.single['created_by'],
        userWithRole(UserRole.admin).id,
      );
      expect(find.text('Blokir unit tersimpan.'), findsOneWidget);
      expect(find.byType(RoomBlockCard), findsNWidgets(2));
    });

    testWidgets('menghapus blokir lewat konfirmasi', (tester) async {
      final FakeAdminRoomDataSource data = await open(tester);
      await openBlocks(tester);

      await tester.tap(find.byTooltip(RegExp('^Hapus blokir')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya, hapus blokir'));
      await tester.pumpAndSettle();

      expect(data.blockRows, isEmpty);
      expect(find.text('Blokir Deluxe dihapus.'), findsOneWidget);
    });
  });
}
