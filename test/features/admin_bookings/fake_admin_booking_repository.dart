import 'package:meowville/core/errors/app_exception.dart';
import 'package:meowville/features/admin_bookings/domain/entities/admin_booking.dart';
import 'package:meowville/features/admin_bookings/domain/entities/booking_decision.dart';
import 'package:meowville/features/admin_bookings/domain/repositories/admin_booking_repository.dart';
import 'package:meowville/features/dashboard/domain/entities/booking_status.dart';

AdminBooking adminBooking({
  String id = '3f9a2b41-0000-4000-8000-000000000001',
  BookingStatus status = BookingStatus.pending,
  String petName = 'Luna',
  String petBreed = 'Persia',
  String ownerName = 'Reza Gunawan',
  String roomType = 'Deluxe',
  double totalPrice = 575000,
  List<BookingAddOn> addOns = const <BookingAddOn>[],
  String? careInstructions,
}) {
  return AdminBooking(
    id: id,
    status: status,
    checkin: DateTime(2026, 10, 15),
    checkout: DateTime(2026, 10, 18),
    createdAt: DateTime(2026, 10, 14, 9, 30),
    totalPrice: totalPrice,
    petName: petName,
    petBreed: petBreed,
    petWeightKg: 3.8,
    petAggressiveness: 'Low',
    ownerName: ownerName,
    ownerEmail: 'reza@contoh.com',
    roomType: roomType,
    includedServices: 'Pembersihan litter box, Makan terjadwal',
    careInstructions: careInstructions,
    addOns: addOns,
  );
}

typedef DecisionCall = ({
  String bookingId,
  BookingDecision decision,
  String adminId,
});

class FakeAdminBookingRepository implements AdminBookingRepository {
  FakeAdminBookingRepository({
    List<AdminBooking> bookings = const <AdminBooking>[],
    this.error,
    this.decisionError,
    this.gate,
  }) : _bookings = List<AdminBooking>.of(bookings);

  final List<AdminBooking> _bookings;
  AppException? error;
  AppException? decisionError;
  Future<void>? gate;

  int listLoads = 0;
  final List<DecisionCall> decisions = <DecisionCall>[];

  @override
  Future<List<AdminBooking>> loadBookings() async {
    listLoads++;
    await gate;
    if (error != null) {
      throw error!;
    }
    return List<AdminBooking>.unmodifiable(_bookings);
  }

  @override
  Future<AdminBooking> loadBooking(String bookingId) async {
    await gate;
    if (error != null) {
      throw error!;
    }
    return _bookings.firstWhere(
      (AdminBooking b) => b.id == bookingId,
      orElse: () =>
          throw const NotFoundException('Reservasi ini tidak ditemukan.'),
    );
  }

  @override
  Future<void> applyDecision({
    required String bookingId,
    required BookingDecision decision,
    required String adminId,
  }) async {
    decisions.add((bookingId: bookingId, decision: decision, adminId: adminId));
    if (decisionError != null) {
      throw decisionError!;
    }
    final int index = _bookings.indexWhere(
      (AdminBooking b) => b.id == bookingId,
    );
    final AdminBooking old = _bookings[index];
    _bookings[index] = AdminBooking(
      id: old.id,
      status: decision.to,
      checkin: old.checkin,
      checkout: old.checkout,
      createdAt: old.createdAt,
      totalPrice: old.totalPrice,
      petName: old.petName,
      petBreed: old.petBreed,
      petWeightKg: old.petWeightKg,
      petAggressiveness: old.petAggressiveness,
      ownerName: old.ownerName,
      ownerEmail: old.ownerEmail,
      roomType: old.roomType,
      includedServices: old.includedServices,
      careInstructions: old.careInstructions,
      addOns: old.addOns,
    );
  }
}
