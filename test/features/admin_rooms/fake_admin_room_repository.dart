import 'package:meowville/core/errors/app_exception.dart';
import 'package:meowville/features/admin_rooms/data/datasources/admin_room_remote_datasource.dart';
import 'package:meowville/features/admin_rooms/data/repositories/admin_room_repository_impl.dart';

JsonRow roomRow(int id, String type, {num price = 150000}) => <String, dynamic>{
  'id': id,
  'room_type': type,
  'description': 'Kamar $type',
  'included_services': 'CCTV, Playtime',
  'price_per_night': price,
};

JsonRow unitRow(int id, int roomId, String code, {bool active = true}) =>
    <String, dynamic>{
      'id': id,
      'room_id': roomId,
      'unit_code': code,
      'is_active': active,
    };

JsonRow bookingRow(
  String id,
  int roomId, {
  String status = 'Confirmed',
  String checkin = '2026-10-11',
  String checkout = '2026-10-14',
  int? unitId,
}) => <String, dynamic>{
  'id': id,
  'room_id': roomId,
  'room_unit_id': unitId,
  'status': status,
  'checkin_date': checkin,
  'checkout_date': checkout,
};

JsonRow blockRow(
  String id,
  int roomId,
  String type, {
  String start = '2026-10-12',
  String end = '2026-10-13',
  int units = 1,
  String? purpose,
}) => <String, dynamic>{
  'id': id,
  'room_id': roomId,
  'date_start': start,
  'date_end': end,
  'blocked_units': units,
  'purpose': purpose,
  'rooms': <String, dynamic>{'room_type': type},
};

class FakeAdminRoomDataSource implements AdminRoomRemoteDataSource {
  FakeAdminRoomDataSource({
    List<JsonRow>? rooms,
    List<JsonRow>? units,
    List<JsonRow>? bookings,
    List<JsonRow>? blocks,
    this.loadError,
    this.gate,
  }) : roomRows = List<JsonRow>.of(rooms ?? const <JsonRow>[]),
       unitRows = List<JsonRow>.of(units ?? const <JsonRow>[]),
       bookingRows = List<JsonRow>.of(bookings ?? const <JsonRow>[]),
       blockRows = List<JsonRow>.of(blocks ?? const <JsonRow>[]);

  final List<JsonRow> roomRows;
  final List<JsonRow> unitRows;
  final List<JsonRow> bookingRows;
  final List<JsonRow> blockRows;
  AppException? loadError;
  AppException? writeError;
  Future<void>? gate;

  final List<JsonRow> insertedBlocks = <JsonRow>[];

  Future<List<JsonRow>> _read(List<JsonRow> rows) async {
    await gate;
    if (loadError != null) {
      throw loadError!;
    }
    return List<JsonRow>.of(rows);
  }

  void _guardWrite() {
    if (writeError != null) {
      throw writeError!;
    }
  }

  @override
  Future<List<JsonRow>> rooms() => _read(roomRows);

  @override
  Future<List<JsonRow>> units({int? roomId}) => _read(
    unitRows
        .where((JsonRow u) => roomId == null || u['room_id'] == roomId)
        .toList(),
  );

  @override
  Future<List<JsonRow>> liveBookings(DateTime today, {int? roomId}) => _read(
    bookingRows
        .where((JsonRow b) => roomId == null || b['room_id'] == roomId)
        .toList(),
  );

  @override
  Future<List<JsonRow>> upcomingBlocks(DateTime today) => _read(blockRows);

  @override
  Future<int> insertRoom(JsonRow values) async {
    _guardWrite();
    final int id =
        roomRows.fold<int>(
          0,
          (int m, JsonRow r) => (r['id'] as int) > m ? r['id'] as int : m,
        ) +
        1;
    roomRows.add(<String, dynamic>{...values, 'id': id});
    return id;
  }

  @override
  Future<void> updateRoom(int roomId, JsonRow values) async {
    _guardWrite();
    final int index = roomRows.indexWhere((JsonRow r) => r['id'] == roomId);
    roomRows[index] = <String, dynamic>{...roomRows[index], ...values};
  }

  @override
  Future<void> setUnitsActive(List<int> unitIds, {required bool active}) async {
    _guardWrite();
    for (int i = 0; i < unitRows.length; i++) {
      if (unitIds.contains(unitRows[i]['id'])) {
        unitRows[i] = <String, dynamic>{...unitRows[i], 'is_active': active};
      }
    }
  }

  @override
  Future<void> insertUnits(int roomId, List<String> codes) async {
    _guardWrite();
    int next = unitRows.fold<int>(
      0,
      (int m, JsonRow u) => (u['id'] as int) > m ? u['id'] as int : m,
    );
    for (final String code in codes) {
      unitRows.add(unitRow(++next, roomId, code));
    }
  }

  @override
  Future<void> deleteRoom(int roomId) async {
    _guardWrite();
    if (bookingRows.any((JsonRow b) => b['room_id'] == roomId)) {
      throw const ConflictException(
        'Tipe kamar ini sudah punya riwayat reservasi, jadi tidak bisa dihapus.',
      );
    }
    roomRows.removeWhere((JsonRow r) => r['id'] == roomId);
    unitRows.removeWhere((JsonRow u) => u['room_id'] == roomId);
    blockRows.removeWhere((JsonRow b) => b['room_id'] == roomId);
  }

  @override
  Future<void> insertBlock(JsonRow values) async {
    _guardWrite();
    insertedBlocks.add(values);
    final String type =
        roomRows.firstWhere(
              (JsonRow r) => r['id'] == values['room_id'],
            )['room_type']
            as String;
    blockRows.add(<String, dynamic>{
      ...values,
      'id': 'blok-${blockRows.length + 1}',
      'rooms': <String, dynamic>{'room_type': type},
    });
  }

  @override
  Future<void> deleteBlock(String blockId) async {
    _guardWrite();
    blockRows.removeWhere((JsonRow b) => b['id'] == blockId);
  }
}

class FakeAdminRoomRepository extends AdminRoomRepositoryImpl {
  FakeAdminRoomRepository._(this.source) : super(source);

  factory FakeAdminRoomRepository({FakeAdminRoomDataSource? source}) =>
      FakeAdminRoomRepository._(source ?? FakeAdminRoomDataSource());

  final FakeAdminRoomDataSource source;
}
