import 'booking_status.dart';
import 'booking_summary.dart';
import 'daily_log_entry.dart';

enum SitterTaskKind { checkIn, checkOut, report }

class SitterTask {
  const SitterTask({required this.kind, required this.booking});

  final SitterTaskKind kind;
  final BookingSummary booking;
}

class SitterDashboard {
  const SitterDashboard({
    required this.guests,
    required this.todayLogs,
    required this.today,
  });

  factory SitterDashboard.compose({
    required List<BookingSummary> guests,
    required List<DailyLogEntry> todayLogs,
    required DateTime today,
  }) {
    return SitterDashboard(guests: guests, todayLogs: todayLogs, today: today);
  }

  final List<BookingSummary> guests;
  final List<DailyLogEntry> todayLogs;
  final DateTime today;

  bool hasReportToday(BookingSummary booking) =>
      todayLogs.any((DailyLogEntry log) => log.bookingId == booking.id);

  List<DailyLogEntry> logsFor(BookingSummary booking) => todayLogs
      .where((DailyLogEntry log) => log.bookingId == booking.id)
      .toList(growable: false);

  List<BookingSummary> get stayingGuests => guests
      .where((BookingSummary b) => b.status == BookingStatus.checkedIn)
      .toList(growable: false);

  List<BookingSummary> get pendingReportGuests => stayingGuests
      .where((BookingSummary b) => !hasReportToday(b))
      .toList(growable: false);

  List<BookingSummary> get completedReportGuests =>
      stayingGuests.where(hasReportToday).toList(growable: false);

  int get stayingCount => stayingGuests.length;

  int get checkinTodayCount =>
      guests.where((BookingSummary b) => b.checkin == today).length;

  int get arrivedTodayCount => guests
      .where(
        (BookingSummary b) =>
            b.checkin == today && b.status == BookingStatus.checkedIn,
      )
      .length;

  int get waitingTodayCount => guests
      .where(
        (BookingSummary b) =>
            b.checkin == today && b.status == BookingStatus.confirmed,
      )
      .length;

  int get checkoutTodayCount =>
      stayingGuests.where((BookingSummary b) => b.checkout == today).length;

  int get pendingReportCount => pendingReportGuests.length;

  List<SitterTask> get tasks {
    final List<SitterTask> timed = <SitterTask>[
      for (final BookingSummary b in guests)
        if (b.status == BookingStatus.confirmed && b.checkin == today)
          SitterTask(kind: SitterTaskKind.checkIn, booking: b),
      for (final BookingSummary b in stayingGuests)
        if (b.checkout == today)
          SitterTask(kind: SitterTaskKind.checkOut, booking: b),
    ];
    final List<SitterTask> reports = <SitterTask>[
      for (final BookingSummary b in pendingReportGuests)
        SitterTask(kind: SitterTaskKind.report, booking: b),
    ];
    return <SitterTask>[...timed, ...reports];
  }
}
