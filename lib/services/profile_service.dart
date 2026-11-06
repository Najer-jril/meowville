import '../core/api_client.dart';
import '../data/models.dart';

class ProfileService {
  ProfileService(this._api);

  final ApiClient _api;

  Future<List<AppUser>> fetchAll() async {
    final rows = await _api.get(
      '/rest/v1/profiles?select=*&order=joined_at.desc',
    );
    return [for (final row in rows as List) AppUser.fromJson(row)];
  }

  Future<AppUser> fetchById(String id) async {
    final rows = await _api.get('/rest/v1/profiles?select=*&id=eq.$id') as List;
    if (rows.isEmpty) throw ApiException(404, 'Profil akun tidak ditemukan');
    return AppUser.fromJson(rows.first);
  }
}
