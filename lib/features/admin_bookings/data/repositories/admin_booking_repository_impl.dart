import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/admin_booking.dart';
import '../../domain/entities/booking_decision.dart';
import '../../domain/repositories/admin_booking_repository.dart';
import '../datasources/admin_booking_remote_datasource.dart';
import '../models/admin_booking_dto.dart';

class AdminBookingRepositoryImpl implements AdminBookingRepository {
  const AdminBookingRepositoryImpl(this._dataSource);

  final AdminBookingRemoteDataSource _dataSource;

  @override
  Future<List<AdminBooking>> loadBookings() async {
    final List<JsonRow> rows = await _dataSource.bookings();
    return rows
        .map((JsonRow row) => AdminBookingDto.fromJson(row).toEntity())
        .toList(growable: false);
  }

  @override
  Future<AdminBooking> loadBooking(String bookingId) async {
    final JsonRow? row = await _dataSource.booking(bookingId);
    if (row == null) {
      throw const NotFoundException(
        'Reservasi ini tidak ditemukan. Mungkin tautannya salah.',
      );
    }
    return AdminBookingDto.fromJson(row).toEntity();
  }

  @override
  Future<void> applyDecision({
    required String bookingId,
    required BookingDecision decision,
    required String adminId,
  }) async {
    final int changed = await _dataSource.updateStatus(
      bookingId: bookingId,
      fromStatus: decision.from.wireValue,
      toStatus: decision.to.wireValue,
      adminId: adminId,
    );
    if (changed == 0) {
      throw const ConflictException(
        'Status reservasi sudah berubah sebelum keputusan Anda tersimpan. '
        'Data terbaru sudah dimuat ulang.',
      );
    }
  }
}
