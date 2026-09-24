import '../entities/admin_booking.dart';
import '../entities/booking_decision.dart';

abstract interface class AdminBookingRepository {
  Future<List<AdminBooking>> loadBookings();

  Future<AdminBooking> loadBooking(String bookingId);

  Future<void> applyDecision({
    required String bookingId,
    required BookingDecision decision,
    required String adminId,
  });
}
