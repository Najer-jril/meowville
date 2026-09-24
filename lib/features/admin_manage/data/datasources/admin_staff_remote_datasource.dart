import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/data_error_mapper.dart';

typedef JsonRow = Map<String, dynamic>;

abstract interface class AdminStaffRemoteDataSource {
  Future<List<JsonRow>> staff();

  Future<void> createStaff({
    required String name,
    required String email,
    required String password,
    required String role,
  });
}

class SupabaseAdminStaffRemoteDataSource implements AdminStaffRemoteDataSource {
  const SupabaseAdminStaffRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<JsonRow>> staff() async {
    try {
      return await _client
          .from('users')
          .select('id, name, email, role, created_at')
          .inFilter('role', <String>['pet_sitter', 'admin'])
          .order('created_at', ascending: false);
    } on Object catch (error) {
      throw mapDataError(
        error,
        fallback: 'Daftar akun staf gagal dimuat. Coba ulangi sebentar lagi.',
      );
    }
  }

  @override
  Future<void> createStaff({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      await _client.rpc<dynamic>(
        'admin_create_staff_account',
        params: <String, dynamic>{
          'p_name': name,
          'p_email': email,
          'p_password': password,
          'p_role': role,
        },
      );
    } on PostgrestException catch (error) {
      switch (error.code) {
        case '22023':
          throw ValidationException(error.message, cause: error);
        case '23505':
          throw ConflictException(error.message, cause: error);
      }
      throw mapDataError(error, fallback: _createFallback);
    } on Object catch (error) {
      throw mapDataError(error, fallback: _createFallback);
    }
  }

  static const String _createFallback =
      'Akun staf belum dibuat. Coba ulangi sebentar lagi.';
}
