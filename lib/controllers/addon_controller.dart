import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../services/addon_service.dart';
import 'load_state.dart';

class AddonController extends ChangeNotifier with LoadState {
  AddonController(this._service);

  final AddonService _service;
  List<Addon> _addons = [];

  List<Addon> get addons => _addons;
  List<Addon> get active => _addons.where((a) => a.active).toList();

  Future<void> load() => runLoad(() async {
    _addons = await _service.fetchAll();
  });

  Future<void> save(Addon draft, {Addon? existing}) async {
    if (existing == null) {
      await _service.create(draft);
    } else {
      await _service.update(draft);
    }
    await load();
  }

  Future<void> setActive(Addon addon, bool active) async {
    await _service.setActive(addon.id, active);
    await load();
  }

  void reset() {
    _addons = [];
    notifyListeners();
  }
}
