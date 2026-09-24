import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/data_error_mapper.dart';
import '../../../../core/utils/relative_date.dart';

typedef JsonRow = Map<String, dynamic>;

const List<String> liveBookingStatuses = <String>[
  'Pending',
  'Confirmed',
  'CheckedIn',
];

abstract interface class AdminRoomRemoteDataSource {
  Future<List<JsonRow>> rooms();

  Future<List<JsonRow>> units({int? roomId});

  Future<List<JsonRow>> liveBookings(DateTime today, {int? roomId});

  Future<List<JsonRow>> upcomingBlocks(DateTime today);

  Future<int> insertRoom(JsonRow values);

  Future<void> updateRoom(int roomId, JsonRow values);

  Future<void> setUnitsActive(List<int> unitIds, {required bool active});

  Future<void> insertUnits(int roomId, List<String> codes);

  Future<void> deleteRoom(int roomId);

  Future<void> insertBlock(JsonRow values);

  Future<void> deleteBlock(String blockId);
}

class SupabaseAdminRoomRemoteDataSource implements AdminRoomRemoteDataSource {
  const SupabaseAdminRoomRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const String _loadFallback =
      'Data kamar gagal dimuat. Coba ulangi sebentar lagi.';
  static const String _saveFallback =
      'Perubahan belum tersimpan. Coba ulangi sebentar lagi.';

  Future<T> _run<T>(Future<T> query, {required String fallback}) async {
    try {
      return await query;
    } on PostgrestException catch (error) {
      // 23505: nilai unik bentrok, misalnya tier atau kode unit yang sudah ada.
      if (error.code == '23505') {
        throw ConflictException(
          'Data ini sudah ada di server. Muat ulang, lalu periksa lagi.',
          cause: error,
        );
      }
      throw mapDataError(error, fallback: fallback);
    } on Object catch (error) {
      throw mapDataError(error, fallback: fallback);
    }
  }

  @override
  Future<List<JsonRow>> rooms() {
    return _run(
      _client
          .from('rooms')
          .select(
            'id, room_type, description, included_services, price_per_night',
          )
          .order('price_per_night', ascending: true),
      fallback: _loadFallback,
    );
  }

  @override
  Future<List<JsonRow>> units({int? roomId}) {
    final PostgrestFilterBuilder<List<JsonRow>> query = _client
        .from('room_units')
        .select('id, room_id, unit_code, is_active');
    return _run(
      roomId == null ? query : query.eq('room_id', roomId),
      fallback: _loadFallback,
    );
  }

  @override
  Future<List<JsonRow>> liveBookings(DateTime today, {int? roomId}) {
    final PostgrestFilterBuilder<List<JsonRow>> query = _client
        .from('bookings')
        .select(
          'id, room_id, room_unit_id, status, checkin_date, checkout_date',
        )
        .inFilter('status', liveBookingStatuses)
        .gte('checkout_date', formatSqlDate(today));
    return _run(
      roomId == null ? query : query.eq('room_id', roomId),
      fallback: _loadFallback,
    );
  }

  @override
  Future<List<JsonRow>> upcomingBlocks(DateTime today) {
    return _run(
      _client
          .from('room_blocks')
          .select(
            'id, room_id, date_start, date_end, blocked_units, purpose, '
            'rooms(room_type)',
          )
          .gte('date_end', formatSqlDate(today))
          .order('date_start', ascending: true),
      fallback: _loadFallback,
    );
  }

  @override
  Future<int> insertRoom(JsonRow values) async {
    final JsonRow row = await _run(
      _client.from('rooms').insert(values).select('id').single(),
      fallback: _saveFallback,
    );
    return (row['id'] as num).toInt();
  }

  @override
  Future<void> updateRoom(int roomId, JsonRow values) {
    return _run(
      _client.from('rooms').update(values).eq('id', roomId),
      fallback: _saveFallback,
    );
  }

  @override
  Future<void> setUnitsActive(List<int> unitIds, {required bool active}) {
    if (unitIds.isEmpty) {
      return Future<void>.value();
    }
    return _run(
      _client
          .from('room_units')
          .update(<String, dynamic>{'is_active': active})
          .inFilter('id', unitIds),
      fallback: _saveFallback,
    );
  }

  @override
  Future<void> insertUnits(int roomId, List<String> codes) {
    if (codes.isEmpty) {
      return Future<void>.value();
    }
    return _run(
      _client.from('room_units').insert(<JsonRow>[
        for (final String code in codes)
          <String, dynamic>{'room_id': roomId, 'unit_code': code},
      ]),
      fallback: _saveFallback,
    );
  }

  @override
  Future<void> deleteRoom(int roomId) async {
    try {
      await _client.from('rooms').delete().eq('id', roomId);
    } on PostgrestException catch (error) {
      // 23503: masih dirujuk bookings, yang tidak ikut terhapus.
      if (error.code == '23503') {
        throw ConflictException(
          'Tipe kamar ini sudah punya riwayat reservasi, jadi tidak bisa '
          'dihapus. Ubah harga atau jumlah unitnya saja.',
          cause: error,
        );
      }
      throw mapDataError(error, fallback: _saveFallback);
    } on Object catch (error) {
      throw mapDataError(error, fallback: _saveFallback);
    }
  }

  @override
  Future<void> insertBlock(JsonRow values) {
    return _run(
      _client.from('room_blocks').insert(values),
      fallback: _saveFallback,
    );
  }

  @override
  Future<void> deleteBlock(String blockId) {
    return _run(
      _client.from('room_blocks').delete().eq('id', blockId),
      fallback: _saveFallback,
    );
  }
}
