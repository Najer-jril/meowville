import '../../../../core/errors/app_exception.dart';
import 'room_type.dart';

class RoomUnit {
  const RoomUnit({
    required this.id,
    required this.roomId,
    required this.code,
    required this.isActive,
  });

  final int id;
  final int roomId;
  final String code;
  final bool isActive;

  int get number => int.tryParse(code.split('-').last) ?? 0;
}

class UnitPlan {
  const UnitPlan({
    this.reactivateIds = const <int>[],
    this.deactivateIds = const <int>[],
    this.newCodes = const <String>[],
  });

  final List<int> reactivateIds;
  final List<int> deactivateIds;
  final List<String> newCodes;

  bool get isEmpty =>
      reactivateIds.isEmpty && deactivateIds.isEmpty && newCodes.isEmpty;

  factory UnitPlan.toReach({
    required int target,
    required RoomType type,
    required List<RoomUnit> units,
    Set<int> bookedUnitIds = const <int>{},
  }) {
    int byNumber(RoomUnit a, RoomUnit b) => a.number.compareTo(b.number);
    final List<RoomUnit> active =
        units.where((RoomUnit u) => u.isActive).toList()..sort(byNumber);
    final List<RoomUnit> inactive =
        units.where((RoomUnit u) => !u.isActive).toList()..sort(byNumber);

    if (target == active.length) {
      return const UnitPlan();
    }

    if (target > active.length) {
      final int needed = target - active.length;
      final List<int> reactivate = inactive
          .take(needed)
          .map((RoomUnit u) => u.id)
          .toList(growable: false);
      int next = units.fold<int>(
        0,
        (int highest, RoomUnit u) => u.number > highest ? u.number : highest,
      );
      final List<String> codes = <String>[
        for (int i = reactivate.length; i < needed; i++)
          '${type.unitPrefix}${(++next).toString().padLeft(2, '0')}',
      ];
      return UnitPlan(reactivateIds: reactivate, newCodes: codes);
    }

    final int surplus = active.length - target;
    final List<int> free = active.reversed
        .where((RoomUnit u) => !bookedUnitIds.contains(u.id))
        .map((RoomUnit u) => u.id)
        .toList(growable: false);
    if (free.length < surplus) {
      throw const ValidationException(
        'Sebagian unit sedang dipakai reservasi aktif, jadi jumlah unit '
        'belum bisa dikurangi sebanyak itu.',
      );
    }
    return UnitPlan(deactivateIds: free.take(surplus).toList(growable: false));
  }
}
