import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/data_error_mapper.dart';

typedef JsonRow = Map<String, dynamic>;

abstract interface class AdminBookingRemoteDataSource {
  Future<List<JsonRow>> bookings();

  Future<JsonRow?> booking(String bookingId);

  Future<int> updateStatus({
    required String bookingId,
    required String fromStatus,
    required String toStatus,
    required String adminId,
  });
}

class SupabaseAdminBookingRemoteDataSource
    implements AdminBookingRemoteDataSource {
  const SupabaseAdminBookingRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const String _columns =
      'id, status, checkin_date, checkout_date, created_at, total_price, '
      'care_instructions, '
      'pets(pet_name, breed, weight_kg, aggressiveness_level), '
      'rooms(room_type, included_services), '
      'owner:users!user_id(name, email), '
      'booking_services(price_at_booking, services(service_name))';

  @override
  Future<List<JsonRow>> bookings() async {
    try {
      return await _client
          .from('bookings')
          .select(_columns)
          .order('created_at', ascending: false);
    } on Object catch (error) {
      throw mapDataError(
        error,
        fallback: 'Daftar reservasi gagal dimuat. Coba ulangi sebentar lagi.',
      );
    }
  }

  @override
  Future<JsonRow?> booking(String bookingId) async {
    try {
      return await _client
          .from('bookings')
          .select(_columns)
          .eq('id', bookingId)
          .maybeSingle();
    } on PostgrestException catch (error) {
      // 22P02: id bukan uuid yang sah, misalnya tautan yang terpotong.
      if (error.code == '22P02') {
        return null;
      }
      throw mapDataError(error, fallback: _detailFallback);
    } on Object catch (error) {
      throw mapDataError(error, fallback: _detailFallback);
    }
  }

  static const String _detailFallback =
      'Detail reservasi gagal dimuat. Coba ulangi sebentar lagi.';

  @override
  Future<int> updateStatus({
    required String bookingId,
    required String fromStatus,
    required String toStatus,
    required String adminId,
  }) async {
    try {
      // Syarat status asal mencegah dua admin menimpa keputusan satu sama lain.
      final List<JsonRow> changed = await _client
          .from('bookings')
          .update(<String, dynamic>{
            'status': toStatus,
            'confirmed_by': adminId,
          })
          .eq('id', bookingId)
          .eq('status', fromStatus)
          .select('id');
      return changed.length;
    } on Object catch (error) {
      throw mapDataError(
        error,
        fallback: 'Keputusan belum tersimpan. Coba ulangi sebentar lagi.',
      );
    }
  }
}
