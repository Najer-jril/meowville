import 'package:flutter_test/flutter_test.dart';
import 'package:meowville/core/errors/app_exception.dart';
import 'package:meowville/features/admin_rooms/domain/entities/room_catalog.dart';
import 'package:meowville/features/admin_rooms/domain/entities/room_drafts.dart';
import 'package:meowville/features/admin_rooms/domain/entities/room_type.dart';
import 'package:meowville/features/admin_rooms/domain/entities/room_unit.dart';
import 'package:meowville/features/admin_rooms/domain/usecases/room_usecases.dart';

import 'fake_admin_room_repository.dart';

RoomUnit _unit(int id, String code, {bool active = true}) =>
    RoomUnit(id: id, roomId: 2, code: code, isActive: active);

RoomDraft _draft({
  RoomType? type = RoomType.deluxe,
  String included = 'CCTV',
  String price = '150000',
  int units = 3,
  int minUnits = 1,
}) => RoomDraft(
  type: type,
  description: '',
  includedServices: included,
  priceText: price,
  unitCount: units,
  minUnits: minUnits,
);

void main() {
  final DateTime today = DateTime(2026, 10, 12);
  DateTime now() => DateTime(2026, 10, 12, 14);

  group('UnitPlan', () {
    final List<RoomUnit> units = <RoomUnit>[
      _unit(1, 'DLX-01'),
      _unit(2, 'DLX-02'),
      _unit(3, 'DLX-03', active: false),
    ];

    test('menambah: hidupkan unit nonaktif dulu, lalu kode baru berurutan', () {
      final UnitPlan plan = UnitPlan.toReach(
        target: 5,
        type: RoomType.deluxe,
        units: units,
      );
      expect(plan.reactivateIds, <int>[3]);
      expect(plan.newCodes, <String>['DLX-04', 'DLX-05']);
      expect(plan.deactivateIds, isEmpty);
    });

    test('mengurangi: nonaktifkan nomor terbesar yang tidak dipesan', () {
      final UnitPlan plan = UnitPlan.toReach(
        target: 1,
        type: RoomType.deluxe,
        units: units,
        bookedUnitIds: <int>{2},
      );
      expect(plan.deactivateIds, <int>[1]);
    });

    test('mengurangi melebihi unit bebas ditolak', () {
      expect(
        () => UnitPlan.toReach(
          target: 0,
          type: RoomType.deluxe,
          units: units,
          bookedUnitIds: <int>{1},
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('tier baru mulai dari 01 dengan prefiks tier', () {
      final UnitPlan plan = UnitPlan.toReach(
        target: 2,
        type: RoomType.suite,
        units: const <RoomUnit>[],
      );
      expect(plan.newCodes, <String>['STE-01', 'STE-02']);
    });

    test('jumlah sama tidak mengubah apa pun', () {
      expect(
        UnitPlan.toReach(
          target: 2,
          type: RoomType.deluxe,
          units: units,
        ).isEmpty,
        isTrue,
      );
    });
  });

  group('RoomDraft', () {
    test('isian lengkap lolos', () {
      expect(_draft().validate(), isEmpty);
    });

    test('paket, harga, dan tipe wajib', () {
      final Map<RoomField, String> errors = _draft(
        type: null,
        included: '  ',
        price: '',
      ).validate();
      expect(
        errors.keys,
        containsAll(<RoomField>[
          RoomField.type,
          RoomField.includedServices,
          RoomField.price,
        ]),
      );
    });

    test('unit di bawah reservasi aktif ditolak', () {
      expect(
        _draft(units: 2, minUnits: 3).validate()[RoomField.units],
        contains('3'),
      );
    });
  });

  group('RoomBlockDraft', () {
    RoomBlockDraft block({
      DateTime? start,
      DateTime? end,
      int units = 1,
      String purpose = '',
    }) => RoomBlockDraft(
      roomId: 1,
      dateStart: start,
      dateEnd: end,
      blockedUnits: units,
      purpose: purpose,
      maxUnits: 4,
      today: today,
    );

    test('tanggal wajib dan selesai tidak boleh sebelum mulai', () {
      expect(block().validate(), contains(BlockField.dates));
      expect(
        block(
          start: DateTime(2026, 10, 15),
          end: DateTime(2026, 10, 14),
        ).validate(),
        contains(BlockField.dates),
      );
      expect(
        block(
          start: DateTime(2026, 10, 15),
          end: DateTime(2026, 10, 15),
        ).validate(),
        isEmpty,
      );
    });

    test('unit melebihi unit aktif dan keperluan terlalu panjang ditolak', () {
      final Map<BlockField, String> errors = block(
        start: today,
        end: today,
        units: 5,
        purpose: 'x' * 101,
      ).validate();
      expect(
        errors.keys,
        containsAll(<BlockField>[BlockField.units, BlockField.purpose]),
      );
    });
  });

  group('katalog dari repository', () {
    FakeAdminRoomRepository seeded() => FakeAdminRoomRepository(
      source: FakeAdminRoomDataSource(
        rooms: <Map<String, dynamic>>[roomRow(1, 'Standard', price: 95000)],
        units: <Map<String, dynamic>>[
          unitRow(1, 1, 'STD-01'),
          unitRow(2, 1, 'STD-02'),
          unitRow(3, 1, 'STD-03'),
          unitRow(4, 1, 'STD-04'),
          unitRow(5, 1, 'STD-05', active: false),
        ],
        bookings: <Map<String, dynamic>>[
          bookingRow('b1', 1, unitId: 1),
          bookingRow('b2', 1, status: 'Pending'),
          bookingRow('b3', 1, checkin: '2026-10-20', checkout: '2026-10-22'),
        ],
        blocks: <Map<String, dynamic>>[
          blockRow('k1', 1, 'Standard', purpose: 'Perbaikan AC'),
          blockRow('k2', 1, 'Standard', start: '2026-10-20', end: '2026-10-21'),
        ],
      ),
    );

    test(
      'okupansi hari ini: Confirmed yang mencakup hari ini dan blokir',
      () async {
        final RoomCatalog catalog = await seeded().loadCatalog(today: today);
        final AdminRoom room = catalog.rooms.single;

        expect(room.activeUnits, 4);
        expect(room.today.occupiedUnits, 1);
        expect(room.today.blockedUnits, 1);
        expect(room.today.availableUnits, 2);
        expect(room.today.blockedPurposes, <String>['Perbaikan AC']);
        expect(room.activeReservations, 3);
        expect(catalog.blocks, hasLength(2));
        expect(catalog.missingTypes, <RoomType>[
          RoomType.deluxe,
          RoomType.suite,
        ]);
      },
    );

    test('simpan: tidak bisa di bawah jumlah reservasi aktif', () async {
      final FakeAdminRoomRepository repository = seeded();
      await expectLater(
        SaveRoomUseCase(repository, now)(roomId: 1, draft: _draft(units: 2)),
        throwsA(isA<ValidationException>()),
      );
      expect(repository.source.roomRows.single['price_per_night'], 95000);
    });

    test('simpan: tarif dan unit berubah, unit nonaktif dihidupkan', () async {
      final FakeAdminRoomRepository repository = seeded();
      await SaveRoomUseCase(repository, now)(
        roomId: 1,
        draft: _draft(type: RoomType.standard, units: 6, price: '100000'),
      );

      final RoomCatalog catalog = await repository.loadCatalog(today: today);
      expect(catalog.rooms.single.tier.pricePerNight, 100000);
      expect(catalog.rooms.single.activeUnits, 6);
      expect(
        repository.source.unitRows.map(
          (Map<String, dynamic> u) => u['unit_code'],
        ),
        contains('STD-06'),
      );
    });

    test('tambah tier baru membuat unitnya', () async {
      final FakeAdminRoomRepository repository = seeded();
      await SaveRoomUseCase(repository, now)(draft: _draft(units: 2));

      final RoomCatalog catalog = await repository.loadCatalog(today: today);
      final AdminRoom deluxe = catalog.rooms.firstWhere(
        (AdminRoom r) => r.type == RoomType.deluxe,
      );
      expect(deluxe.activeUnits, 2);
      expect(deluxe.units.map((RoomUnit u) => u.code), <String>[
        'DLX-01',
        'DLX-02',
      ]);
    });

    test('blokir mengirim created_by admin dan tanggal SQL', () async {
      final FakeAdminRoomRepository repository = seeded();
      await CreateRoomBlockUseCase(repository)(
        draft: RoomBlockDraft(
          roomId: 1,
          dateStart: DateTime(2026, 10, 15),
          dateEnd: DateTime(2026, 10, 16),
          blockedUnits: 2,
          purpose: '  Renovasi  ',
          maxUnits: 4,
          today: today,
        ),
        adminId: 'admin-1',
      );

      expect(repository.source.insertedBlocks.single, <String, dynamic>{
        'room_id': 1,
        'date_start': '2026-10-15',
        'date_end': '2026-10-16',
        'blocked_units': 2,
        'purpose': 'Renovasi',
        'created_by': 'admin-1',
      });
    });

    test('blokir tanpa sesi admin ditolak', () async {
      await expectLater(
        CreateRoomBlockUseCase(seeded())(
          draft: RoomBlockDraft(
            roomId: 1,
            dateStart: today,
            dateEnd: today,
            blockedUnits: 1,
            purpose: '',
            maxUnits: 4,
            today: today,
          ),
          adminId: null,
        ),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });
}
