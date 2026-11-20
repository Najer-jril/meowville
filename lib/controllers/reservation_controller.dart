import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../services/reservation_service.dart';
import '../utils/clock.dart';
import 'load_state.dart';
import 'room_controller.dart';

/// semua reservasi untuk admin dan sitter
class ReservationController extends ChangeNotifier with LoadState {
  ReservationController(this._service, this._rooms);

  final ReservationService _service;
  final RoomController _rooms;

  List<Reservation> _all = [];

  /// terbaru dulu, sesuai urutan dari server
  List<Reservation> get latest => _all;
  List<Reservation> get pending =>
      _all.where((r) => r.status == ReservationStatus.pending).toList();

  Future<void> load() => runLoad(() async {
    _all = await _service.fetchAll();
  });

  Reservation? byId(int id) => _all.where((r) => r.id == id).firstOrNull;

  int activeCountFor(RoomType type) =>
      _all.where((r) => r.roomType == type && r.status.isActive).length;

  /// unit yang kosong di semua malam dalam rentang. Server tetap mengecek ulang saat approve, jadi ini hanya untuk mengisi dropdown.
  List<String> freeUnits(
    RoomType type,
    DateTime start,
    DateTime endExclusive, {
    Reservation? ignore,
  }) {
    final lastNight = endExclusive.subtract(const Duration(days: 1));
    return type.units.where((unit) {
      final busy = _all.any(
        (r) =>
            r != ignore &&
            r.unit == unit &&
            r.roomType == type &&
            r.status.holdsUnit &&
            r.overlaps(start, lastNight),
      );
      final blocked = _rooms.blocks.any(
        (b) =>
            b.roomType == type &&
            b.unit == unit &&
            !b.start.isAfter(lastNight) &&
            !b.end.isBefore(start),
      );
      return !busy && !blocked;
    }).toList();
  }

  Future<void> approve(Reservation r, String unit) =>
      _mutate(() => _service.approve(r.id, unit));

  Future<void> reject(Reservation r, String note) =>
      _mutate(() => _service.reject(r.id, note));

  Future<void> cancel(Reservation r) => _mutate(() => _service.cancel(r.id));

  Future<void> checkIn(Reservation r) => _mutate(() => _service.checkIn(r.id));

  Future<void> checkOut(Reservation r) =>
      _mutate(() => _service.checkOut(r.id));

  Future<void> _mutate(Future<void> Function() action) async {
    await action();
    await load();
    _rooms.refreshAvailability();
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Reservation> checkInsToday() {
    final today = Clock.today();
    return _all
        .where((r) => _sameDay(r.checkIn, today) && r.status.holdsUnit)
        .toList();
  }

  List<Reservation> checkOutsToday() {
    final today = Clock.today();
    return _all
        .where(
          (r) =>
              _sameDay(r.checkOut, today) &&
              (r.status == ReservationStatus.checkedIn ||
                  r.status == ReservationStatus.completed),
        )
        .toList();
  }

  List<Reservation> get staying =>
      _all.where((r) => r.status == ReservationStatus.checkedIn).toList();

  List<Reservation> get awaitingCheckIn {
    final today = Clock.today();
    return _all
        .where(
          (r) =>
              r.status == ReservationStatus.confirmed &&
              !r.checkIn.isAfter(today),
        )
        .toList()
      ..sort((a, b) => a.checkIn.compareTo(b.checkIn));
  }

  List<Reservation> get stayingNotLeaving {
    final today = Clock.today();
    return staying.where((r) => r.checkOut.isAfter(today)).toList()
      ..sort((a, b) => a.checkOut.compareTo(b.checkOut));
  }

  List<Reservation> get dueCheckOut {
    final today = Clock.today();
    return staying.where((r) => !r.checkOut.isAfter(today)).toList();
  }

  /// pemasukan per tipe kamar untuk reservasi yang check-in dalam rentang, Memakai harga yang terkunci saat booking.
  ReportData report(DateTime start, DateTime end) {
    final rows = <RoomType, ReportRow>{};
    var nights = 0;
    final list = _all.where(
      (r) =>
          r.status.countsAsRevenue &&
          !r.checkIn.isBefore(start) &&
          !r.checkIn.isAfter(end),
    );
    for (final r in list) {
      final row = rows.putIfAbsent(r.roomType, () => ReportRow(r.roomType));
      row.bookings++;
      row.revenue += r.total;
      nights += r.nights;
    }
    final sorted = rows.values.toList()
      ..sort((a, b) => b.bookings.compareTo(a.bookings));
    final count = list.length;
    return ReportData(
      rows: sorted,
      bookings: count,
      revenue: sorted.fold(0, (sum, r) => sum + r.revenue),
      avgNights: count == 0 ? 0 : nights / count,
    );
  }

  void reset() {
    _all = [];
    notifyListeners();
  }
}
