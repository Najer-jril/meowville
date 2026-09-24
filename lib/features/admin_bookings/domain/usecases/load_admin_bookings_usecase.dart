import '../entities/admin_booking.dart';
import '../repositories/admin_booking_repository.dart';

class LoadAdminBookingsUseCase {
  const LoadAdminBookingsUseCase(this._repository);

  final AdminBookingRepository _repository;

  Future<List<AdminBooking>> call() => _repository.loadBookings();
}

class LoadAdminBookingDetailUseCase {
  const LoadAdminBookingDetailUseCase(this._repository);

  final AdminBookingRepository _repository;

  Future<AdminBooking> call(String bookingId) =>
      _repository.loadBooking(bookingId);
}
