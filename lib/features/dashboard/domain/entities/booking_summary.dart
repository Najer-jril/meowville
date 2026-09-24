import '../../../../core/utils/relative_date.dart';
import 'booking_status.dart';
import 'pet_summary.dart';

class BookingSummary {
  const BookingSummary({
    required this.id,
    required this.status,
    required this.checkin,
    required this.checkout,
    required this.pet,
    required this.roomType,
    required this.createdAt,
    this.roomId,
    this.pricePerNight,
    this.totalPrice,
    this.careInstructions,
    this.unitCode,
    this.ownerName,
    this.assignedSitterId,
    this.paymentProofPath,
  });

  final String id;
  final BookingStatus status;
  final DateTime checkin;
  final DateTime checkout;
  final PetSummary pet;
  final String roomType;
  final DateTime createdAt;
  final int? roomId;
  final double? pricePerNight;
  final double? totalPrice;
  final String? careInstructions;
  final String? unitCode;
  final String? ownerName;
  final String? assignedSitterId;
  final String? paymentProofPath;

  String get code => '#${id.replaceAll('-', '').substring(0, 8).toLowerCase()}';

  int get nights => daysBetween(checkin, checkout);

  bool get hasPaymentProof =>
      paymentProofPath != null && paymentProofPath!.isNotEmpty;

  bool get hasCareInstructions =>
      careInstructions != null && careInstructions!.trim().isNotEmpty;

  bool occupiesUnitOn(DateTime day) {
    final bool holdsUnit =
        status == BookingStatus.confirmed || status == BookingStatus.checkedIn;
    return holdsUnit && !day.isBefore(checkin) && !day.isAfter(checkout);
  }

  int stayDay(DateTime today) => daysBetween(checkin, today) + 1;
}
