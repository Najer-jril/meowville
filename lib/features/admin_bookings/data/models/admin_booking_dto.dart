import '../../../../core/utils/relative_date.dart';
import '../../../dashboard/data/models/json_readers.dart';
import '../../../dashboard/domain/entities/booking_status.dart';
import '../../domain/entities/admin_booking.dart';

class AdminBookingDto {
  const AdminBookingDto._(this._json);

  factory AdminBookingDto.fromJson(Map<String, dynamic> json) =>
      AdminBookingDto._(json);

  final Map<String, dynamic> _json;

  AdminBooking toEntity() {
    final Map<String, dynamic>? pet = asMap(_json['pets']);
    final Map<String, dynamic>? room = asMap(_json['rooms']);
    final Map<String, dynamic>? owner = asMap(_json['owner']);
    final List<Object?> services =
        (_json['booking_services'] as List<Object?>?) ?? const <Object?>[];

    return AdminBooking(
      id: _json['id'] as String,
      status: BookingStatus.fromWireValue(_json['status'] as String),
      checkin: parseDateOnly(_json['checkin_date'] as String),
      checkout: parseDateOnly(_json['checkout_date'] as String),
      createdAt: parseServerTimestamp(_json['created_at'] as String),
      totalPrice: asDouble(_json['total_price']) ?? 0,
      careInstructions: asNonEmptyString(_json['care_instructions']),
      petName: asNonEmptyString(pet?['pet_name']) ?? 'Kucing',
      petBreed: asNonEmptyString(pet?['breed']) ?? '',
      petWeightKg: asDouble(pet?['weight_kg']),
      petAggressiveness: asNonEmptyString(pet?['aggressiveness_level']),
      ownerName: asNonEmptyString(owner?['name']) ?? 'Pawrent',
      ownerEmail: asNonEmptyString(owner?['email']),
      roomType: asNonEmptyString(room?['room_type']) ?? '',
      includedServices: asNonEmptyString(room?['included_services']),
      addOns: <BookingAddOn>[
        for (final Object? row in services)
          if (asMap(row) case final Map<String, dynamic> line)
            BookingAddOn(
              name:
                  asNonEmptyString(asMap(line['services'])?['service_name']) ??
                  'Layanan tambahan',
              priceAtBooking: asDouble(line['price_at_booking']) ?? 0,
            ),
      ],
    );
  }
}
