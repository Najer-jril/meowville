import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../data/models.dart';
import '../services/room_service.dart';
import '../services/storage_service.dart';
import '../utils/clock.dart';
import '../widgets/app_photo.dart';
import 'load_state.dart';

class RoomController extends ChangeNotifier with LoadState {
  RoomController(this._service, this._storage);

  final RoomService _service;
  final StorageService _storage;

  String? _userId;
  List<RoomType> _types = [];
  List<UnitBlock> _blocks = [];
  final Map<String, DayAvailability> _availability = {};
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  List<RoomType> get types => _types;
  List<RoomType> get active => _types.where((t) => t.active).toList();
  List<UnitBlock> get blocks => _blocks;
  int get totalActiveUnits => active.fold(0, (sum, t) => sum + t.unitCount);

  Future<void> load({String? userId, bool withBlocks = false}) =>
      runLoad(() async {
        _userId = userId ?? _userId;
        _types = await _service.fetchAll();
        if (withBlocks) _blocks = await _service.fetchBlocks(Clock.today());
      });

  bool prefixTaken(String prefix, {RoomType? except}) => _types.any(
    (t) => t != except && t.prefix.toUpperCase() == prefix.toUpperCase(),
  );

  Future<void> save(RoomType draft, {RoomType? existing}) async {
    final photo = isLocalPhoto(draft.photo)
        ? await _storage.upload(Buckets.rooms, _userId!, draft.photo!)
        : draft.photo;
    final type = draft.copyWith(photo: photo);
    if (existing == null) {
      await _service.create(type);
    } else {
      await _service.update(type);
    }
    await load();
    refreshAvailability();
  }

  Future<void> setActive(RoomType type, bool active) async {
    await _service.setActive(type.id, active);
    await load();
  }

  static String _key(int typeId, DateTime day) => '$typeId|${isoDate(day)}';

  /// jumlah dari cache [loadAvailability] terakhir. Kalau rentangnya belum dimuat, kembalikan hari kosong.
  DayAvailability availability(RoomType type, DateTime day) =>
      _availability[_key(type.id, day)] ??
      DayAvailability(
        roomTypeId: type.id,
        day: day,
        units: type.unitCount,
        occupied: 0,
        pending: 0,
        blocked: 0,
      );

  /// load [start]..[end] (inklusif) dan memperluas rentang yang diingat, supaya [refreshAvailability] memuat ulang semua yang tampil di layar.
  Future<void> loadAvailability(DateTime start, DateTime end) async {
    _rangeStart = _rangeStart == null || start.isBefore(_rangeStart!)
        ? start
        : _rangeStart;
    _rangeEnd = _rangeEnd == null || end.isAfter(_rangeEnd!) ? end : _rangeEnd;
    final days = await _service.availability(start: start, end: end);
    for (final d in days) {
      _availability[_key(d.roomTypeId, d.day)] = d;
    }
    notifyListeners();
  }

  Future<void> refreshAvailability() async {
    if (_rangeStart == null) return;
    await loadAvailability(_rangeStart!, _rangeEnd!);
  }

  /// jumlah unit kosong paling sedikit per id tipe kamar, dari semua malam dalam rentang.
  Future<Map<int, int>> remainingBetween(
    DateTime start,
    DateTime endExclusive,
  ) async {
    final days = await _service.availability(
      start: start,
      end: endExclusive.subtract(const Duration(days: 1)),
    );
    final result = <int, int>{};
    for (final d in days) {
      final left = d.remaining;
      result[d.roomTypeId] = math.min(result[d.roomTypeId] ?? left, left);
    }
    return result;
  }

  List<UnitBlock> blocksFor(RoomType type) =>
      _blocks.where((b) => b.roomType == type).toList()
        ..sort((a, b) => a.start.compareTo(b.start));

  /// return pesan error, atau null kalau blok berhasil disimpan.
  Future<String?> addBlock({
    required RoomType type,
    required String unit,
    required DateTime start,
    required DateTime end,
    required String reason,
  }) async {
    try {
      await _service.addBlock(
        typeId: type.id,
        unit: unit,
        start: start,
        end: end,
        reason: reason,
      );
    } on ApiException catch (e) {
      return e.message;
    }
    _blocks = await _service.fetchBlocks(Clock.today());
    await refreshAvailability();
    notifyListeners();
    return null;
  }

  Future<void> removeBlock(UnitBlock block) async {
    await _service.removeBlock(block.id);
    _blocks = await _service.fetchBlocks(Clock.today());
    await refreshAvailability();
    notifyListeners();
  }

  void reset() {
    _userId = null;
    _types = [];
    _blocks = [];
    _availability.clear();
    _rangeStart = null;
    _rangeEnd = null;
    notifyListeners();
  }
}
