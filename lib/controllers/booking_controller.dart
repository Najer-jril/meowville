import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../services/reservation_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_photo.dart';
import 'load_state.dart';
import 'room_controller.dart';

/// reservasi milik owner yang sedang login.
class BookingController extends ChangeNotifier with LoadState {
  BookingController(this._service, this._storage, this._rooms);

  final ReservationService _service;
  final StorageService _storage;
  final RoomController _rooms;

  String? _ownerId;
  List<Reservation> _reservations = [];
  Map<int, int> _remaining = {};
  bool _checkingRemaining = false;

  /// terbaru dulu.
  List<Reservation> get reservations => _reservations;

  /// jumlah unit kosong per id tipe kamar, untuk rentang [loadRemaining] terakhir.
  Map<int, int> get remaining => _remaining;
  bool get checkingRemaining => _checkingRemaining;

  Future<void> load([String? ownerId]) => runLoad(() async {
    _ownerId = ownerId ?? _ownerId;
    _reservations = await _service.fetchMine(_ownerId!);
  });

  Reservation? activeFor(Cat cat) {
    final list =
        _reservations.where((r) => r.cat == cat && r.status.isActive).toList()
          ..sort((a, b) => a.checkIn.compareTo(b.checkIn));
    return list.isEmpty ? null : list.first;
  }

  Reservation? clashFor(Cat cat, DateTime start, DateTime endExclusive) {
    for (final r in _reservations) {
      if (r.cat == cat &&
          r.status.isActive &&
          r.checkIn.isBefore(endExclusive) &&
          r.checkOut.isAfter(start)) {
        return r;
      }
    }
    return null;
  }

  DateTime proofDeadline(Reservation r) =>
      r.createdAt.add(const Duration(hours: 24));

  Future<void> loadRemaining(DateTime start, DateTime endExclusive) async {
    _checkingRemaining = true;
    notifyListeners();
    try {
      _remaining = await _rooms.remainingBetween(start, endExclusive);
    } finally {
      _checkingRemaining = false;
      notifyListeners();
    }
  }

  Future<Reservation> create({
    required Cat cat,
    required RoomType type,
    required DateTime checkIn,
    required DateTime checkOut,
    required Set<Addon> addons,
    String? proof,
  }) async {
    final proofPath = isLocalPhoto(proof)
        ? await _storage.upload(Buckets.proofs, _ownerId!, proof!)
        : proof;
    final id = await _service.create(
      catId: cat.id,
      typeId: type.id,
      checkIn: checkIn,
      checkOut: checkOut,
      addonIds: [for (final a in addons) a.id],
      proof: proofPath,
    );
    await load();
    _rooms.refreshAvailability();
    return _reservations.firstWhere((r) => r.id == id);
  }

  Future<void> uploadProof(Reservation r, String localPath) async {
    final path = await _storage.upload(Buckets.proofs, _ownerId!, localPath);
    await _service.uploadProof(r.id, path);
    await load();
  }

  Future<void> cancel(Reservation r) async {
    await _service.cancel(r.id);
    await load();
    _rooms.refreshAvailability();
  }

  void reset() {
    _ownerId = null;
    _reservations = [];
    _remaining = {};
    notifyListeners();
  }
}
