import 'booking_status.dart';
import 'booking_summary.dart';
import 'daily_log_entry.dart';
import 'room_tier.dart';
import 'tier_occupancy.dart';

class RoomUnitInfo {
  const RoomUnitInfo({
    required this.id,
    required this.roomId,
    required this.unitCode,
  });

  final int id;
  final int roomId;
  final String unitCode;
}

class RoomBlockInfo {
  const RoomBlockInfo({
    required this.roomId,
    required this.blockedUnits,
    this.purpose,
  });

  final int roomId;
  final int blockedUnits;
  final String? purpose;
}

class AdminDashboard {
  const AdminDashboard({
    required this.today,
    required this.pending,
    required this.liveBookings,
    required this.occupancy,
    required this.missingReports,
    required this.recent,
    required this.servicesByBooking,
  });

  factory AdminDashboard.compose({
    required List<BookingSummary> liveBookings,
    required List<BookingSummary> recent,
    required List<RoomTier> rooms,
    required List<RoomUnitInfo> units,
    required List<RoomBlockInfo> blocks,
    required List<DailyLogEntry> todayLogs,
    required Map<String, List<String>> servicesByBooking,
    required DateTime today,
  }) {
    final List<BookingSummary> pending =
        liveBookings
            .where((BookingSummary b) => b.status == BookingStatus.pending)
            .toList()
          ..sort(
            (BookingSummary a, BookingSummary b) =>
                a.createdAt.compareTo(b.createdAt),
          );

    final List<TierOccupancy> occupancy = <TierOccupancy>[
      for (final RoomTier tier in rooms)
        TierOccupancy(
          tier: tier,
          totalUnits: units
              .where((RoomUnitInfo u) => u.roomId == tier.id)
              .length,
          occupiedUnits: liveBookings
              .where(
                (BookingSummary b) =>
                    b.roomId == tier.id && b.occupiesUnitOn(today),
              )
              .length,
          blockedUnits: blocks
              .where((RoomBlockInfo b) => b.roomId == tier.id)
              .fold(0, (int sum, RoomBlockInfo b) => sum + b.blockedUnits),
          blockedPurposes: <String>[
            for (final RoomBlockInfo b in blocks)
              if (b.roomId == tier.id &&
                  b.purpose != null &&
                  b.purpose!.trim().isNotEmpty)
                b.purpose!.trim(),
          ],
        ),
    ];

    final Set<String> loggedIds = todayLogs
        .map((DailyLogEntry log) => log.bookingId)
        .toSet();
    final List<BookingSummary> missingReports = liveBookings
        .where(
          (BookingSummary b) =>
              b.status == BookingStatus.checkedIn && !loggedIds.contains(b.id),
        )
        .toList(growable: false);

    return AdminDashboard(
      today: today,
      pending: pending,
      liveBookings: liveBookings,
      occupancy: occupancy,
      missingReports: missingReports,
      recent: recent,
      servicesByBooking: servicesByBooking,
    );
  }

  final DateTime today;
  final List<BookingSummary> pending;
  final List<BookingSummary> liveBookings;
  final List<TierOccupancy> occupancy;
  final List<BookingSummary> missingReports;
  final List<BookingSummary> recent;
  final Map<String, List<String>> servicesByBooking;

  int get pendingCount => pending.length;

  int get stayingCount => liveBookings
      .where((BookingSummary b) => b.status == BookingStatus.checkedIn)
      .length;

  int get checkinTodayCount => liveBookings
      .where(
        (BookingSummary b) =>
            b.checkin == today &&
            (b.status == BookingStatus.confirmed ||
                b.status == BookingStatus.checkedIn),
      )
      .length;

  int get arrivedTodayCount => liveBookings
      .where(
        (BookingSummary b) =>
            b.checkin == today && b.status == BookingStatus.checkedIn,
      )
      .length;

  int get waitingTodayCount => checkinTodayCount - arrivedTodayCount;

  int get checkoutTodayCount => liveBookings
      .where(
        (BookingSummary b) =>
            b.checkout == today && b.status == BookingStatus.checkedIn,
      )
      .length;

  int get totalUnits =>
      occupancy.fold(0, (int sum, TierOccupancy t) => sum + t.totalUnits);

  int get occupiedUnits =>
      occupancy.fold(0, (int sum, TierOccupancy t) => sum + t.filledUnits);

  int get availableUnits =>
      occupancy.fold(0, (int sum, TierOccupancy t) => sum + t.availableUnits);

  int get capacityPercent =>
      totalUnits == 0 ? 0 : (occupiedUnits * 100 / totalUnits).round();

  List<String> servicesFor(BookingSummary booking) =>
      servicesByBooking[booking.id] ?? const <String>[];
}
