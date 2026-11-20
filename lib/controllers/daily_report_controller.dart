import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../services/daily_report_service.dart';
import '../services/storage_service.dart';
import '../utils/clock.dart';
import '../widgets/app_photo.dart';
import 'load_state.dart';

class DailyReportController extends ChangeNotifier with LoadState {
  DailyReportController(this._service, this._storage);

  final DailyReportService _service;
  final StorageService _storage;

  List<DailyReport> _reports = [];

  /// terbaru dulu.
  List<DailyReport> get history => _reports;

  Future<void> load() => runLoad(() async {
    _reports = await _service.fetchAll();
  });

  List<DailyReport> forReservation(Reservation r) =>
      _reports.where((d) => d.reservation == r).toList();

  static bool _isToday(DateTime t) {
    final today = Clock.today();
    return t.year == today.year && t.month == today.month && t.day == today.day;
  }

  DailyReport? reportToday(Reservation r) =>
      _reports.where((d) => d.reservation == r && _isToday(d.time)).firstOrNull;

  int countToday(AppUser reporter) =>
      _reports.where((d) => d.reporter == reporter && _isToday(d.time)).length;

  Future<void> add({
    required Reservation reservation,
    required AppUser reporter,
    required String food,
    required String drink,
    required String mood,
    String note = '',
    String? photo,
  }) async {
    final url = isLocalPhoto(photo)
        ? await _storage.upload(Buckets.reports, reporter.id, photo!)
        : photo;
    await _service.create(
      reservationId: reservation.id,
      reporterId: reporter.id,
      food: food,
      drink: drink,
      mood: mood,
      note: note,
      photo: url,
    );
    await load();
  }

  void reset() {
    _reports = [];
    notifyListeners();
  }
}
