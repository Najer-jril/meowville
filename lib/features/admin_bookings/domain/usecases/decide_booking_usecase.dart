import '../../../../core/errors/app_exception.dart';
import '../entities/admin_booking.dart';
import '../entities/booking_decision.dart';
import '../repositories/admin_booking_repository.dart';

class DecideBookingUseCase {
  const DecideBookingUseCase(this._repository);

  final AdminBookingRepository _repository;

  Future<void> call({
    required AdminBooking booking,
    required BookingDecision decision,
    required String? adminId,
  }) async {
    if (adminId == null || adminId.isEmpty) {
      throw const UnauthorizedException(
        'Sesi admin tidak ditemukan. Masuk ulang, lalu coba lagi.',
      );
    }
    if (decision.from != booking.status) {
      throw const ValidationException(
        'Keputusan ini tidak berlaku untuk status reservasi sekarang.',
      );
    }
    await _repository.applyDecision(
      bookingId: booking.id,
      decision: decision,
      adminId: adminId,
    );
  }
}
