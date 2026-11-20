import '../core/api_client.dart';
import '../data/models.dart';

class ReservationService {
  ReservationService(this._api);

  final ApiClient _api;

  Future<List<Reservation>> fetchMine(String ownerId) => _fetch(
    '/rest/v1/reservations?select=${Reservation.select}'
    '&owner_id=eq.$ownerId&order=created_at.desc',
  );

  Future<List<Reservation>> fetchAll() => _fetch(
    '/rest/v1/reservations?select=${Reservation.select}&order=created_at.desc',
  );

  Future<Reservation> fetchById(int id) async {
    final rows = await _fetch(
      '/rest/v1/reservations?select=${Reservation.select}&id=eq.$id',
    );
    if (rows.isEmpty) throw ApiException(404, 'Reservasi tidak ditemukan');
    return rows.first;
  }

  Future<List<Reservation>> _fetch(String path) async {
    final rows = await _api.get(path);
    return [for (final row in rows as List) Reservation.fromJson(row)];
  }

  /// reeturn id reservasi baru.
  Future<int> create({
    required int catId,
    required int typeId,
    required DateTime checkIn,
    required DateTime checkOut,
    required List<int> addonIds,
    String? proof,
  }) async => await _api.rpc('create_reservation', {
    'p_cat': catId,
    'p_type': typeId,
    'p_check_in': isoDate(checkIn),
    'p_check_out': isoDate(checkOut),
    'p_addons': addonIds,
    'p_proof': proof,
  }) as int;

  Future<void> cancel(int id) => _api.rpc('cancel_reservation', {'p_id': id});

  Future<void> uploadProof(int id, String path) =>
      _api.rpc('upload_payment_proof', {'p_id': id, 'p_path': path});

  Future<void> approve(int id, String unit) =>
      _api.rpc('approve_reservation', {'p_id': id, 'p_unit': unit});

  Future<void> reject(int id, String note) =>
      _api.rpc('reject_reservation', {'p_id': id, 'p_note': note});

  Future<void> checkIn(int id) =>
      _api.rpc('check_in_reservation', {'p_id': id});

  Future<void> checkOut(int id) =>
      _api.rpc('check_out_reservation', {'p_id': id});
}
