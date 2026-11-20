import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../services/settings_service.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._service);

  final SettingsService _service;

  AppSettings _settings = AppSettings.fallback;
  AppSettings get settings => _settings;

  /// gagal memuat tidak menghentikan app, nilai fallback tetap dipakai
  Future<void> load() async {
    try {
      _settings = await _service.fetch();
      notifyListeners();
    } on Object {
      // tetap memakai nilai sebelumnya
    }
  }
}
