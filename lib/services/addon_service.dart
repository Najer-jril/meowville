import '../core/api_client.dart';
import '../data/models.dart';

class AddonService {
  AddonService(this._api);

  final ApiClient _api;

  Future<List<Addon>> fetchAll() async {
    final rows = await _api.get('/rest/v1/addons?select=*&order=name');
    return [for (final row in rows as List) Addon.fromJson(row)];
  }

  Future<Addon> create(Addon addon) async =>
      Addon.fromJson(await _api.insert('addons', addon.toJson()));

  Future<Addon> update(Addon addon) async {
    final rows = await _api.patch(
      '/rest/v1/addons?id=eq.${addon.id}',
      addon.toJson(),
    ) as List;
    return Addon.fromJson(rows.first);
  }

  Future<void> setActive(int id, bool active) =>
      _api.patch('/rest/v1/addons?id=eq.$id', {'active': active});
}
