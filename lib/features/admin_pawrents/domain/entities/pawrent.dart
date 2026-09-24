import '../../../dashboard/domain/entities/booking_status.dart';

class PawrentSummary {
  const PawrentSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.petCount,
    this.bookingStatuses = const <BookingStatus>[],
  });

  final String id;
  final String name;
  final String email;
  final int petCount;
  final List<BookingStatus> bookingStatuses;

  int get bookingCount => bookingStatuses.length;

  bool get isStaying => bookingStatuses.contains(BookingStatus.checkedIn);

  bool matchesQuery(String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return true;
    }
    return name.toLowerCase().contains(needle) ||
        email.toLowerCase().contains(needle);
  }
}

enum PawrentFilter { all, staying }

List<PawrentSummary> filterPawrents(
  List<PawrentSummary> pawrents, {
  PawrentFilter filter = PawrentFilter.all,
  String query = '',
}) {
  return pawrents
      .where(
        (PawrentSummary pawrent) =>
            (filter == PawrentFilter.all || pawrent.isStaying) &&
            pawrent.matchesQuery(query),
      )
      .toList(growable: false);
}

class PawrentPet {
  const PawrentPet({
    required this.id,
    required this.name,
    required this.breed,
    this.weightKg,
    this.aggressiveness,
  });

  final String id;
  final String name;
  final String breed;
  final double? weightKg;
  final String? aggressiveness;
}

class PawrentBooking {
  const PawrentBooking({
    required this.id,
    required this.status,
    required this.checkin,
    required this.checkout,
    required this.totalPrice,
    required this.petName,
    required this.roomType,
  });

  final String id;
  final BookingStatus status;
  final DateTime checkin;
  final DateTime checkout;

  final double totalPrice;
  final String petName;
  final String roomType;
}

class PawrentDetail {
  const PawrentDetail._({
    required this.id,
    required this.name,
    required this.email,
    required this.joinedAt,
    required this.pets,
    required this.bookings,
  });

  factory PawrentDetail.compose({
    required String id,
    required String name,
    required String email,
    required DateTime joinedAt,
    List<PawrentPet> pets = const <PawrentPet>[],
    List<PawrentBooking> bookings = const <PawrentBooking>[],
  }) {
    return PawrentDetail._(
      id: id,
      name: name,
      email: email,
      joinedAt: joinedAt,
      pets: List<PawrentPet>.unmodifiable(
        List<PawrentPet>.of(pets)..sort(
          (PawrentPet a, PawrentPet b) =>
              a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        ),
      ),
      bookings: List<PawrentBooking>.unmodifiable(
        List<PawrentBooking>.of(bookings)..sort(
          (PawrentBooking a, PawrentBooking b) =>
              b.checkin.compareTo(a.checkin),
        ),
      ),
    );
  }

  final String id;
  final String name;
  final String email;
  final DateTime joinedAt;
  final List<PawrentPet> pets;
  final List<PawrentBooking> bookings;

  bool get isStaying => bookings.any(
    (PawrentBooking booking) => booking.status == BookingStatus.checkedIn,
  );
}
