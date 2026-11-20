import '../core/api_client.dart';
import '../data/models.dart';

class SettingsService {
  SettingsService(this._api);

  final ApiClient _api;

  Future<AppSettings> fetch() async {
    final rows = await _api.get('/rest/v1/app_settings?select=*') as List;
    if (rows.isEmpty) return AppSettings.fallback;
    return AppSettings.fromJson(rows.first as Map<String, dynamic>);
  }
}
