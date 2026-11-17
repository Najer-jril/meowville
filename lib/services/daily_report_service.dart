import '../core/api_client.dart';
import '../data/models.dart';

class DailyReportService {
  DailyReportService(this._api);

  final ApiClient _api;

  /// Terbaru dulu. RLS membatasi owner hanya bisa lihat laporan kucingnya
  /// sendiri.
  Future<List<DailyReport>> fetchAll() async {
    final rows = await _api.get(
      '/rest/v1/daily_reports?select=${DailyReport.select}&order=time.desc',
    );
    return [for (final row in rows as List) DailyReport.fromJson(row)];
  }

  Future<DailyReport> create({
    required int reservationId,
    required String reporterId,
    required String food,
    required String drink,
    required String mood,
    String note = '',
    String? photo,
  }) async {
    final row = await _api.insert('daily_reports', {
      'reservation_id': reservationId,
      'reporter_id': reporterId,
      'food': food,
      'drink': drink,
      'mood': mood,
      'note': note,
      'photo': photo,
    });
    final rows = await _api.get(
      '/rest/v1/daily_reports?select=${DailyReport.select}&id=eq.${row['id']}',
    );
    return DailyReport.fromJson((rows as List).first);
  }
}
