import '../../../../core/utils/relative_date.dart';
import '../../domain/entities/booking_status.dart';
import '../../domain/entities/booking_summary.dart';
import '../../domain/entities/pet_summary.dart';
import 'json_readers.dart';
import 'pet_dto.dart';

class BookingDto {
  const BookingDto._(this._json);

  factory BookingDto.fromJson(Map<String, dynamic> json) => BookingDto._(json);

  final Map<String, dynamic> _json;

  BookingSummary toEntity(PublicUrlResolver resolveUrl) {
    final Map<String, dynamic>? petJson = asMap(_json['pets']);
    final Map<String, dynamic>? roomJson = asMap(_json['rooms']);
    final Map<String, dynamic>? unitJson = asMap(_json['room_units']);
    final Map<String, dynamic>? ownerJson = asMap(_json['owner']);

    final PetSummary pet = petJson == null
        ? const PetSummary(id: '', name: 'Kucing', breed: '')
        : PetDto.fromJson(petJson).toEntity(resolveUrl);

    return BookingSummary(
      id: _json['id'] as String,
      status: BookingStatus.fromWireValue(_json['status'] as String),
      checkin: parseDateOnly(_json['checkin_date'] as String),
      checkout: parseDateOnly(_json['checkout_date'] as String),
      pet: pet,
      roomType: (roomJson?['room_type'] as String?) ?? '',
      roomId: (roomJson?['id'] as num?)?.toInt(),
      pricePerNight: asDouble(roomJson?['price_per_night']),
      createdAt: _json['created_at'] == null
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : parseServerTimestamp(_json['created_at'] as String),
      totalPrice: asDouble(_json['total_price']),
      careInstructions: asNonEmptyString(_json['care_instructions']),
      unitCode: asNonEmptyString(unitJson?['unit_code']),
      ownerName: asNonEmptyString(ownerJson?['name']),
      assignedSitterId: asNonEmptyString(_json['assigned_sitter_id']),
      paymentProofPath: asNonEmptyString(_json['payment_proof_url']),
    );
  }
}
