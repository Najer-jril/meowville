import '../core/api_client.dart';
import '../data/models.dart';

class CatService {
  CatService(this._api);

  final ApiClient _api;

  Future<List<Cat>> fetchMine(String ownerId) async {
    final rows = await _api.get(
      '/rest/v1/cats?select=*&owner_id=eq.$ownerId&deleted=is.false'
      '&order=created_at.desc',
    );
    return [for (final row in rows as List) Cat.fromJson(row)];
  }

  Future<Cat> create(
    String ownerId, {
    required String name,
    required String breed,
    required double weightKg,
    String? photo,
  }) async => Cat.fromJson(
    await _api.insert('cats', {
      'owner_id': ownerId,
      'name': name,
      'breed': breed,
      'weight_kg': weightKg,
      'photo': photo,
    }),
  );

  Future<Cat> update(
    int id, {
    required String name,
    required String breed,
    required double weightKg,
    String? photo,
  }) async {
    final rows = await _api.patch('/rest/v1/cats?id=eq.$id', {
      'name': name,
      'breed': breed,
      'weight_kg': weightKg,
      'photo': photo,
    }) as List;
    return Cat.fromJson(rows.first);
  }

  /// Soft delete. Server menolak kalau kucing masih punya reservasi aktif.
  Future<void> delete(int id) => _api.rpc('delete_cat', {'p_id': id});
}
