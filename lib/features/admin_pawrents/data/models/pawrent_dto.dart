import '../../../../core/utils/relative_date.dart';
import '../../../dashboard/data/models/json_readers.dart';
import '../../../dashboard/domain/entities/booking_status.dart';
import '../../domain/entities/pawrent.dart';

List<Map<String, dynamic>> _rows(Object? value) => <Map<String, dynamic>>[
  if (value is List<Object?>)
    for (final Object? row in value)
      if (asMap(row) case final Map<String, dynamic> map) map,
];

String _name(Map<String, dynamic> json) =>
    asNonEmptyString(json['name']) ?? 'Pawrent tanpa nama';

String _email(Map<String, dynamic> json) =>
    asNonEmptyString(json['email']) ?? '';

PawrentSummary pawrentSummaryFromJson(Map<String, dynamic> json) {
  return PawrentSummary(
    id: json['id'] as String,
    name: _name(json),
    email: _email(json),
    petCount: _rows(json['pets']).length,
    bookingStatuses: <BookingStatus>[
      for (final Map<String, dynamic> booking in _rows(json['bookings']))
        BookingStatus.fromWireValue(booking['status'] as String),
    ],
  );
}

PawrentDetail pawrentDetailFromJson(Map<String, dynamic> json) {
  return PawrentDetail.compose(
    id: json['id'] as String,
    name: _name(json),
    email: _email(json),
    joinedAt: parseServerTimestamp(json['created_at'] as String),
    pets: <PawrentPet>[
      for (final Map<String, dynamic> pet in _rows(json['pets']))
        PawrentPet(
          id: pet['id'] as String,
          name: asNonEmptyString(pet['pet_name']) ?? 'Kucing',
          breed: asNonEmptyString(pet['breed']) ?? '',
          weightKg: asDouble(pet['weight_kg']),
          aggressiveness: asNonEmptyString(pet['aggressiveness_level']),
        ),
    ],
    bookings: <PawrentBooking>[
      for (final Map<String, dynamic> booking in _rows(json['bookings']))
        PawrentBooking(
          id: booking['id'] as String,
          status: BookingStatus.fromWireValue(booking['status'] as String),
          checkin: parseDateOnly(booking['checkin_date'] as String),
          checkout: parseDateOnly(booking['checkout_date'] as String),
          totalPrice: asDouble(booking['total_price']) ?? 0,
          petName:
              asNonEmptyString(asMap(booking['pets'])?['pet_name']) ?? 'Kucing',
          roomType:
              asNonEmptyString(asMap(booking['rooms'])?['room_type']) ?? '',
        ),
    ],
  );
}
