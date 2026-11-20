import 'package:flutter/foundation.dart';

import '../core/api_client.dart';

import '../data/models.dart';
import '../services/cat_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_photo.dart';
import 'load_state.dart';

class PetController extends ChangeNotifier with LoadState {
  PetController(this._service, this._storage);

  final CatService _service;
  final StorageService _storage;

  String? _ownerId;

  /// Aksi setelah logout atau sesi direset ditolak, bukan crash.
  String get _owner => _ownerId ?? (throw ApiException(401, 'Sesi berakhir, silakan login ulang'));
  List<Cat> _cats = [];

  List<Cat> get cats => _cats;

  Future<void> load([String? ownerId]) => runLoad(() async {
    _ownerId = ownerId ?? _ownerId;
    _cats = await _service.fetchMine(_owner);
  });

  Future<Cat> save({
    Cat? existing,
    required String name,
    required String breed,
    required double weightKg,
    String? photo,
  }) async {
    final url = isLocalPhoto(photo)
        ? await _storage.upload(Buckets.cats, _owner, photo!)
        : photo;
    final cat = existing == null
        ? await _service.create(
            _owner,
            name: name,
            breed: breed,
            weightKg: weightKg,
            photo: url,
          )
        : await _service.update(
            existing.id,
            name: name,
            breed: breed,
            weightKg: weightKg,
            photo: url,
          );
    await load();
    return cat;
  }

  Future<void> delete(Cat cat) async {
    await _service.delete(cat.id);
    await load();
  }

  void reset() {
    _ownerId = null;
    _cats = [];
    notifyListeners();
  }
}
