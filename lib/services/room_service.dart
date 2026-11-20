import '../core/api_client.dart';
import '../data/models.dart';

class RoomService {
  RoomService(this._api);

  final ApiClient _api;

  Future<List<RoomType>> fetchAll() async {
    final rows = await _api.get('/rest/v1/room_types?select=*&order=price.asc');
    return [for (final row in rows as List) RoomType.fromJson(row)];
  }

  Future<RoomType> create(RoomType type) async =>
      RoomType.fromJson(await _api.insert('room_types', type.toJson()));

  Future<RoomType> update(RoomType type) async {
    final rows = await _api.patch(
      '/rest/v1/room_types?id=eq.${type.id}',
      type.toJson(),
    ) as List;
    return RoomType.fromJson(rows.first);
  }

  Future<void> setActive(int id, bool active) =>
      _api.patch('/rest/v1/room_types?id=eq.$id', {'active': active});

  /// Jumlah per hari untuk [start]..[end] (inklusif). [typeId] null berarti
  /// semua tipe.
  Future<List<DayAvailability>> availability({
    int? typeId,
    required DateTime start,
    required DateTime end,
  }) async {
    final rows = await _api.rpc('room_availability', {
      'p_type': typeId,
      'p_start': isoDate(start),
      'p_end': isoDate(end),
    });
    return [for (final row in rows as List) DayAvailability.fromJson(row)];
  }

  /// Blok yang belum berakhir sebelum [from].
  Future<List<UnitBlock>> fetchBlocks(DateTime from) async {
    final rows = await _api.get(
      '/rest/v1/unit_blocks?select=*,room_type:room_types(*)'
      '&end_date=gte.${isoDate(from)}&order=start_date',
    );
    return [for (final row in rows as List) UnitBlock.fromJson(row)];
  }

  Future<int> addBlock({
    required int typeId,
    required String unit,
    required DateTime start,
    required DateTime end,
    required String reason,
  }) async => await _api.rpc('add_unit_block', {
    'p_type': typeId,
    'p_unit': unit,
    'p_start': isoDate(start),
    'p_end': isoDate(end),
    'p_reason': reason,
  }) as int;

  Future<void> removeBlock(int id) =>
      _api.delete('/rest/v1/unit_blocks?id=eq.$id');
}
