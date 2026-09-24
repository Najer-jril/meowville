import '../../../dashboard/domain/entities/room_tier.dart';
import '../../../dashboard/domain/entities/tier_occupancy.dart';
import 'room_type.dart';
import 'room_unit.dart';

class AdminRoom {
  const AdminRoom({
    required this.type,
    required this.today,
    required this.units,
    required this.activeReservations,
  });

  final RoomType type;

  final TierOccupancy today;

  final List<RoomUnit> units;

  final int activeReservations;

  RoomTier get tier => today.tier;
  int get id => tier.id;
  int get activeUnits => today.totalUnits;
}

class RoomBlock {
  const RoomBlock({
    required this.id,
    required this.roomId,
    required this.roomType,
    required this.dateStart,
    required this.dateEnd,
    required this.blockedUnits,
    this.purpose,
  });

  final String id;
  final int roomId;
  final String roomType;
  final DateTime dateStart;
  final DateTime dateEnd;
  final int blockedUnits;
  final String? purpose;

  bool coversDay(DateTime day) =>
      !day.isBefore(dateStart) && !day.isAfter(dateEnd);
}

class RoomCatalog {
  const RoomCatalog({
    required this.today,
    required this.rooms,
    required this.blocks,
  });

  final DateTime today;
  final List<AdminRoom> rooms;

  final List<RoomBlock> blocks;

  List<RoomType> get missingTypes => RoomType.values
      .where((RoomType type) => rooms.every((AdminRoom r) => r.type != type))
      .toList(growable: false);

  AdminRoom? roomById(int id) {
    for (final AdminRoom room in rooms) {
      if (room.id == id) {
        return room;
      }
    }
    return null;
  }
}
