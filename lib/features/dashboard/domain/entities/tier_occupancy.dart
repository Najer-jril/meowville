import 'room_tier.dart';

class TierOccupancy {
  const TierOccupancy({
    required this.tier,
    required this.totalUnits,
    required this.occupiedUnits,
    required this.blockedUnits,
    required this.blockedPurposes,
  });

  final RoomTier tier;
  final int totalUnits;
  final int occupiedUnits;
  final int blockedUnits;
  final List<String> blockedPurposes;

  int get filledUnits =>
      occupiedUnits > totalUnits ? totalUnits : occupiedUnits;

  int get availableUnits {
    final int free = totalUnits - occupiedUnits - blockedUnits;
    return free < 0 ? 0 : free;
  }

  int get percent =>
      totalUnits == 0 ? 0 : (filledUnits * 100 / totalUnits).round();
}
