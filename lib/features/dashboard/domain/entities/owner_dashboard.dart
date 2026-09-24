import 'booking_status.dart';
import 'booking_summary.dart';
import 'daily_log_entry.dart';
import 'pet_summary.dart';
import 'room_tier.dart';

enum OwnerStayState { active, upcoming, none }

class OwnerDashboard {
  const OwnerDashboard({
    required this.active,
    required this.upcoming,
    required this.history,
    required this.pets,
    required this.stayingPetIds,
    required this.todayLogs,
    required this.rooms,
  });

  static const int historyLimit = 5;

  factory OwnerDashboard.compose({
    required List<BookingSummary> bookings,
    required List<PetSummary> pets,
    required List<RoomTier> rooms,
    required List<DailyLogEntry> todayLogs,
    required DateTime today,
  }) {
    final BookingSummary? active = findActive(bookings);

    final List<BookingSummary> upcoming =
        bookings
            .where(
              (BookingSummary b) =>
                  (b.status == BookingStatus.pending ||
                      b.status == BookingStatus.confirmed) &&
                  !b.checkin.isBefore(today),
            )
            .toList()
          ..sort(
            (BookingSummary a, BookingSummary b) =>
                a.checkin.compareTo(b.checkin),
          );

    final Set<String> shown = <String>{
      if (active != null) active.id,
      ...upcoming.map((BookingSummary b) => b.id),
    };
    final List<BookingSummary> history =
        bookings.where((BookingSummary b) => !shown.contains(b.id)).toList()
          ..sort(
            (BookingSummary a, BookingSummary b) =>
                b.checkin.compareTo(a.checkin),
          );

    return OwnerDashboard(
      active: active,
      upcoming: upcoming,
      history: history.take(historyLimit).toList(growable: false),
      pets: pets,
      stayingPetIds: bookings
          .where((BookingSummary b) => b.status == BookingStatus.checkedIn)
          .map((BookingSummary b) => b.pet.id)
          .toSet(),
      todayLogs: todayLogs,
      rooms: rooms,
    );
  }

  final BookingSummary? active;
  final List<BookingSummary> upcoming;
  final List<BookingSummary> history;
  final List<PetSummary> pets;
  final Set<String> stayingPetIds;
  final List<DailyLogEntry> todayLogs;
  final List<RoomTier> rooms;

  static BookingSummary? findActive(List<BookingSummary> bookings) {
    for (final BookingSummary booking in bookings) {
      if (booking.status == BookingStatus.checkedIn) {
        return booking;
      }
    }
    return null;
  }

  OwnerStayState get stayState {
    if (active != null) {
      return OwnerStayState.active;
    }
    if (upcoming.isNotEmpty) {
      return OwnerStayState.upcoming;
    }
    return OwnerStayState.none;
  }

  BookingSummary? get nextUpcoming => upcoming.isEmpty ? null : upcoming.first;
}
