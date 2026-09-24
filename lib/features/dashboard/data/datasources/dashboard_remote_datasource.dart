import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/data_error_mapper.dart';
import '../../../../core/utils/relative_date.dart';

typedef JsonRows = List<Map<String, dynamic>>;

abstract interface class DashboardRemoteDataSource {
  Future<JsonRows> ownerBookings(String userId);

  Future<JsonRows> ownerPets(String userId);

  Future<JsonRows> rooms();

  Future<JsonRows> ownerDailyLogs(String bookingId, DateTime day);

  Future<JsonRows> sitterGuests(String sitterId);

  Future<JsonRows> dailyLogsFor(List<String> bookingIds, DateTime day);

  Future<JsonRows> adminLiveBookings();

  Future<JsonRows> recentBookings(int limit);

  Future<JsonRows> activeRoomUnits();

  Future<JsonRows> roomBlocksOn(DateTime day);

  Future<JsonRows> loggedBookingIds(DateTime day);

  Future<JsonRows> bookingServices(List<String> bookingIds);

  Future<String> signedPaymentProofUrl(String path);
}

class SupabaseDashboardRemoteDataSource implements DashboardRemoteDataSource {
  const SupabaseDashboardRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const String _petColumns =
      'id, pet_name, breed, sex, weight_kg, photo_url';
  static const String _bookingColumns =
      'id, checkin_date, checkout_date, status, total_price, care_instructions, '
      'created_at, room_unit_id, payment_proof_url, assigned_sitter_id';

  Future<JsonRows> _run(Future<List<Map<String, dynamic>>> query) async {
    try {
      return await query;
    } on Object catch (error) {
      throw mapDataError(
        error,
        fallback:
            'Data dashboard gagal dimuat. Coba ulangi beberapa saat lagi.',
      );
    }
  }

  @override
  Future<JsonRows> ownerBookings(String userId) {
    return _run(
      _client
          .from('bookings')
          .select(
            '$_bookingColumns, '
            'pets($_petColumns), '
            'rooms(id, room_type, price_per_night), '
            'room_units(unit_code)',
          )
          .eq('user_id', userId)
          .order('checkin_date', ascending: false),
    );
  }

  @override
  Future<JsonRows> ownerPets(String userId) {
    return _run(_client.from('pets').select(_petColumns).eq('user_id', userId));
  }

  @override
  Future<JsonRows> rooms() {
    return _run(
      _client
          .from('rooms')
          .select(
            'id, room_type, description, included_services, price_per_night',
          )
          .order('price_per_night', ascending: true),
    );
  }

  @override
  Future<JsonRows> ownerDailyLogs(String bookingId, DateTime day) {
    return _run(
      _client
          .from('daily_logs')
          .select(
            'id, booking_id, log_date, eating_time, pet_mood, note, photo_url, '
            'created_at, author:users!noted_by(name)',
          )
          .eq('booking_id', bookingId)
          .eq('log_date', formatSqlDate(day))
          .order('created_at', ascending: false),
    );
  }

  @override
  Future<JsonRows> sitterGuests(String sitterId) {
    return _run(
      _client
          .from('bookings')
          .select(
            '$_bookingColumns, '
            'pets($_petColumns), '
            'rooms(id, room_type), '
            'room_units(unit_code), '
            'owner:users!user_id(name)',
          )
          .eq('assigned_sitter_id', sitterId)
          .inFilter('status', <String>['Confirmed', 'CheckedIn'])
          .order('checkin_date', ascending: true),
    );
  }

  @override
  Future<JsonRows> dailyLogsFor(List<String> bookingIds, DateTime day) {
    if (bookingIds.isEmpty) {
      return Future<JsonRows>.value(<Map<String, dynamic>>[]);
    }
    return _run(
      _client
          .from('daily_logs')
          .select(
            'id, booking_id, log_date, eating_time, pet_mood, note, photo_url, '
            'created_at',
          )
          .inFilter('booking_id', bookingIds)
          .eq('log_date', formatSqlDate(day)),
    );
  }

  @override
  Future<JsonRows> adminLiveBookings() {
    return _run(
      _client
          .from('bookings')
          .select(
            '$_bookingColumns, '
            'pets($_petColumns), '
            'rooms(id, room_type, price_per_night), '
            'room_units(unit_code), '
            'owner:users!user_id(name)',
          )
          .inFilter('status', <String>['Pending', 'Confirmed', 'CheckedIn']),
    );
  }

  @override
  Future<JsonRows> recentBookings(int limit) {
    return _run(
      _client
          .from('bookings')
          .select(
            '$_bookingColumns, '
            'pets($_petColumns), '
            'rooms(id, room_type, price_per_night), '
            'room_units(unit_code), '
            'owner:users!user_id(name)',
          )
          .order('created_at', ascending: false)
          .limit(limit),
    );
  }

  @override
  Future<JsonRows> activeRoomUnits() {
    return _run(
      _client
          .from('room_units')
          .select('id, room_id, unit_code, is_active')
          .eq('is_active', true),
    );
  }

  @override
  Future<JsonRows> roomBlocksOn(DateTime day) {
    final String sqlDay = formatSqlDate(day);
    return _run(
      _client
          .from('room_blocks')
          .select('room_id, blocked_units, purpose, date_start, date_end')
          .lte('date_start', sqlDay)
          .gte('date_end', sqlDay),
    );
  }

  @override
  Future<JsonRows> loggedBookingIds(DateTime day) {
    return _run(
      _client
          .from('daily_logs')
          .select('id, booking_id, log_date')
          .eq('log_date', formatSqlDate(day)),
    );
  }

  @override
  Future<JsonRows> bookingServices(List<String> bookingIds) {
    if (bookingIds.isEmpty) {
      return Future<JsonRows>.value(<Map<String, dynamic>>[]);
    }
    return _run(
      _client
          .from('booking_services')
          .select('booking_id, services(service_name)')
          .inFilter('booking_id', bookingIds),
    );
  }

  @override
  Future<String> signedPaymentProofUrl(String path) async {
    try {
      return await _client.storage
          .from('payment-proofs')
          .createSignedUrl(path, 60);
    } on Object catch (error) {
      throw mapDataError(
        error,
        fallback: 'Bukti pembayaran belum bisa dibuka. Coba ulangi.',
      );
    }
  }
}
