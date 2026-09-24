import '../entities/room_catalog.dart';
import '../entities/room_type.dart';
import '../entities/room_unit.dart';

class RoomFields {
  const RoomFields({
    required this.type,
    required this.description,
    required this.includedServices,
    required this.pricePerNight,
  });

  final RoomType type;
  final String? description;
  final String includedServices;
  final double pricePerNight;
}

class RoomUnitsState {
  const RoomUnitsState({
    required this.units,
    required this.bookedUnitIds,
    required this.activeReservations,
  });

  final List<RoomUnit> units;
  final Set<int> bookedUnitIds;
  final int activeReservations;
}

class NewRoomBlock {
  const NewRoomBlock({
    required this.roomId,
    required this.dateStart,
    required this.dateEnd,
    required this.blockedUnits,
    required this.purpose,
    required this.createdBy,
  });

  final int roomId;
  final DateTime dateStart;
  final DateTime dateEnd;
  final int blockedUnits;
  final String? purpose;
  final String createdBy;
}

abstract interface class AdminRoomRepository {
  Future<RoomCatalog> loadCatalog({required DateTime today});

  Future<RoomUnitsState> loadUnits(int roomId, {required DateTime today});

  Future<int> createRoom(RoomFields fields);

  Future<void> updateRoom(int roomId, RoomFields fields);

  Future<void> applyUnitPlan(int roomId, UnitPlan plan);

  Future<void> deleteRoom(int roomId);

  Future<void> createBlock(NewRoomBlock block);

  Future<void> deleteBlock(String blockId);
}
