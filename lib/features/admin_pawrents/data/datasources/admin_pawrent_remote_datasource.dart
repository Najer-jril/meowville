import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/data_error_mapper.dart';

abstract interface class AdminPawrentRemoteDataSource {
  Future<List<Map<String, dynamic>>> pawrents();

  Future<Map<String, dynamic>?> pawrent(String userId);
}

class SupabaseAdminPawrentRemoteDataSource
    implements AdminPawrentRemoteDataSource {
  const SupabaseAdminPawrentRemoteDataSource(this._client);

  final SupabaseClient _client;

  // bookings punya beberapa FK ke users (user_id, confirmed_by, penjaga),
  // jadi relasinya disebut lewat kolom user_id.
  static const String _listColumns =
      'id, name, email, pets(id), bookings!user_id(status)';

  static const String _detailColumns =
      'id, name, email, created_at, '
      'pets(id, pet_name, breed, weight_kg, aggressiveness_level), '
      'bookings!user_id(id, status, checkin_date, checkout_date, total_price, '
      'pets(pet_name), rooms(room_type))';

  static const String _detailFallback =
      'Data pawrent gagal dimuat. Coba ulangi sebentar lagi.';

  @override
  Future<List<Map<String, dynamic>>> pawrents() async {
    try {
      return await _client
          .from('users')
          .select(_listColumns)
          .eq('role', 'pet_owner')
          .order('name');
    } on Object catch (error) {
      throw mapDataError(
        error,
        fallback: 'Daftar pawrent gagal dimuat. Coba ulangi sebentar lagi.',
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> pawrent(String userId) async {
    try {
      return await _client
          .from('users')
          .select(_detailColumns)
          .eq('id', userId)
          .eq('role', 'pet_owner')
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
}
