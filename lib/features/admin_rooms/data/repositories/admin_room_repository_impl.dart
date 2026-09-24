import 'dart:async';

import '../../../../core/errors/data_error_mapper.dart';
import '../../../../core/utils/relative_date.dart';
import '../../../dashboard/data/models/json_readers.dart';
import '../../../dashboard/data/models/room_dtos.dart';
import '../../../dashboard/domain/entities/room_tier.dart';
import '../../../dashboard/domain/entities/tier_occupancy.dart';
import '../../domain/entities/room_catalog.dart';
import '../../domain/entities/room_type.dart';
import '../../domain/entities/room_unit.dart';
import '../../domain/repositories/admin_room_repository.dart';
import '../datasources/admin_room_remote_datasource.dart';

class AdminRoomRepositoryImpl implements AdminRoomRepository {
  const AdminRoomRepositoryImpl(this._dataSource);

  final AdminRoomRemoteDataSource _dataSource;

  static Future<T> _all<T>(Future<T> waiting) async {
    try {
      return await waiting;
    } on ParallelWaitError<Object?, Object?> catch (error) {
      throw mapParallelWaitError(
        error,
        fallback: 'Data kamar gagal dimuat. Coba ulangi sebentar lagi.',
      );
    }
  }

  static RoomUnit _unit(JsonRow row) => RoomUnit(
    id: (row['id'] as num).toInt(),
    roomId: (row['room_id'] as num).toInt(),
    code: row['unit_code'] as String,
    isActive: row['is_active'] as bool? ?? true,
  );

  static bool _occupiesToday(JsonRow booking, DateTime today) {
    final String status = booking['status'] as String;
    if (status != 'Confirmed' && status != 'CheckedIn') {
      return false;
    }
    // Sama dengan BookingSummary.occupiesUnitOn di dashboard.
    final DateTime checkin = parseDateOnly(booking['checkin_date'] as String);
    final DateTime checkout = parseDateOnly(booking['checkout_date'] as String);
    return !today.isBefore(checkin) && !today.isAfter(checkout);
  }

  static RoomBlock _block(JsonRow row) => RoomBlock(
    id: row['id'] as String,
    roomId: (row['room_id'] as num).toInt(),
    roomType: asNonEmptyString(asMap(row['rooms'])?['room_type']) ?? '',
    dateStart: parseDateOnly(row['date_start'] as String),
    dateEnd: parseDateOnly(row['date_end'] as String),
    blockedUnits: (row['blocked_units'] as num?)?.toInt() ?? 1,
    purpose: asNonEmptyString(row['purpose']),
  );

  @override
  Future<RoomCatalog> loadCatalog({required DateTime today}) async {
    final (
      List<JsonRow> roomRows,
      List<JsonRow> unitRows,
      List<JsonRow> bookingRows,
      List<JsonRow> blockRows,
    ) = await _all(
      (
        _dataSource.rooms(),
        _dataSource.units(),
        _dataSource.liveBookings(today),
        _dataSource.upcomingBlocks(today),
      ).wait,
    );

    final List<RoomUnit> units = unitRows.map(_unit).toList(growable: false);
    final List<RoomBlock> blocks = blockRows
        .map(_block)
        .toList(growable: false);

    final List<AdminRoom> rooms = <AdminRoom>[];
    for (final JsonRow row in roomRows) {
      final RoomTier tier = RoomDto.fromJson(row).toEntity();
      final RoomType? type = RoomType.fromWireValue(tier.roomType);
      if (type == null) {
        continue;
      }
      final List<RoomUnit> own = units
          .where((RoomUnit u) => u.roomId == tier.id)
          .toList(growable: false);
      final List<JsonRow> bookings = bookingRows
          .where((JsonRow b) => (b['room_id'] as num).toInt() == tier.id)
          .toList(growable: false);
      final List<RoomBlock> blockedToday = blocks
          .where((RoomBlock b) => b.roomId == tier.id && b.coversDay(today))
          .toList(growable: false);

      rooms.add(
        AdminRoom(
          type: type,
          units: own,
          activeReservations: bookings.length,
          today: TierOccupancy(
            tier: tier,
            totalUnits: own.where((RoomUnit u) => u.isActive).length,
            occupiedUnits: bookings
                .where((JsonRow b) => _occupiesToday(b, today))
                .length,
            blockedUnits: blockedToday.fold(
              0,
              (int sum, RoomBlock b) => sum + b.blockedUnits,
            ),
            blockedPurposes: <String>[
              for (final RoomBlock b in blockedToday)
                if (b.purpose != null) b.purpose!,
            ],
          ),
        ),
      );
    }

    return RoomCatalog(today: today, rooms: rooms, blocks: blocks);
  }

  @override
  Future<RoomUnitsState> loadUnits(
    int roomId, {
    required DateTime today,
  }) async {
    final (List<JsonRow> unitRows, List<JsonRow> bookingRows) = await _all(
      (
        _dataSource.units(roomId: roomId),
        _dataSource.liveBookings(today, roomId: roomId),
      ).wait,
    );
    return RoomUnitsState(
      units: unitRows.map(_unit).toList(growable: false),
      bookedUnitIds: <int>{
        for (final JsonRow b in bookingRows)
          if (b['room_unit_id'] is num) (b['room_unit_id'] as num).toInt(),
      },
      activeReservations: bookingRows.length,
    );
  }

  static JsonRow _roomValues(RoomFields fields) => <String, dynamic>{
    'room_type': fields.type.wireValue,
    'description': fields.description,
    'included_services': fields.includedServices,
    'price_per_night': fields.pricePerNight,
  };

  @override
  Future<int> createRoom(RoomFields fields) =>
      _dataSource.insertRoom(_roomValues(fields));

  @override
  Future<void> updateRoom(int roomId, RoomFields fields) =>
      _dataSource.updateRoom(roomId, _roomValues(fields));

  @override
  Future<void> applyUnitPlan(int roomId, UnitPlan plan) async {
    await _dataSource.setUnitsActive(plan.reactivateIds, active: true);
    await _dataSource.setUnitsActive(plan.deactivateIds, active: false);
    await _dataSource.insertUnits(roomId, plan.newCodes);
  }

  @override
  Future<void> deleteRoom(int roomId) => _dataSource.deleteRoom(roomId);

  @override
  Future<void> createBlock(NewRoomBlock block) {
    return _dataSource.insertBlock(<String, dynamic>{
      'room_id': block.roomId,
      'date_start': formatSqlDate(block.dateStart),
      'date_end': formatSqlDate(block.dateEnd),
      'blocked_units': block.blockedUnits,
      'purpose': block.purpose,
      'created_by': block.createdBy,
    });
  }

  @override
  Future<void> deleteBlock(String blockId) => _dataSource.deleteBlock(blockId);
}
