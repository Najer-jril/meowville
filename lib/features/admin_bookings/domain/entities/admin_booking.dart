import '../../../../core/utils/relative_date.dart';
import '../../../dashboard/domain/entities/booking_status.dart';
import 'booking_decision.dart';

class BookingAddOn {
  const BookingAddOn({required this.name, required this.priceAtBooking});

  final String name;

  final double priceAtBooking;
}

class AdminBooking {
  const AdminBooking({
    required this.id,
    required this.status,
    required this.checkin,
    required this.checkout,
    required this.createdAt,
    required this.totalPrice,
    required this.petName,
    required this.petBreed,
    required this.ownerName,
    required this.roomType,
    this.petWeightKg,
    this.petAggressiveness,
    this.ownerEmail,
    this.includedServices,
    this.careInstructions,
    this.addOns = const <BookingAddOn>[],
  });

  final String id;
  final BookingStatus status;
  final DateTime checkin;
  final DateTime checkout;
  final DateTime createdAt;
  final double totalPrice;
  final String petName;
  final String petBreed;
  final double? petWeightKg;
  final String? petAggressiveness;
  final String ownerName;
  final String? ownerEmail;
  final String roomType;
  final String? includedServices;
  final String? careInstructions;
  final List<BookingAddOn> addOns;

  String get code => '#${id.replaceAll('-', '').substring(0, 8).toLowerCase()}';

  int get nights => daysBetween(checkin, checkout);

  double get addOnTotal => addOns.fold<double>(
    0,
    (double sum, BookingAddOn addOn) => sum + addOn.priceAtBooking,
  );

  double get roomSubtotal => totalPrice - addOnTotal;

  List<BookingDecision> get decisions => BookingDecision.availableFor(status);

  bool matchesQuery(String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return true;
    }
    return petName.toLowerCase().contains(needle) ||
        ownerName.toLowerCase().contains(needle);
  }
}

List<AdminBooking> filterAdminBookings(
  List<AdminBooking> bookings, {
  BookingStatus? status,
  String query = '',
}) {
  return bookings
      .where(
        (AdminBooking booking) =>
            (status == null || booking.status == status) &&
            booking.matchesQuery(query),
      )
      .toList(growable: false);
}
