import '../../../dashboard/domain/entities/booking_status.dart';

enum BookingDecision {
  approve(from: BookingStatus.pending, to: BookingStatus.confirmed),
  reject(from: BookingStatus.pending, to: BookingStatus.rejected),
  cancel(from: BookingStatus.confirmed, to: BookingStatus.cancelled);

  const BookingDecision({required this.from, required this.to});

  final BookingStatus from;
  final BookingStatus to;

  static List<BookingDecision> availableFor(BookingStatus status) =>
      BookingDecision.values
          .where((BookingDecision decision) => decision.from == status)
          .toList(growable: false);
}
