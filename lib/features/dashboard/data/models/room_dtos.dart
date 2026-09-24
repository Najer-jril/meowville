import '../../domain/entities/admin_dashboard.dart';
import '../../domain/entities/room_tier.dart';
import 'json_readers.dart';

class RoomDto {
  const RoomDto._(this._json);

  factory RoomDto.fromJson(Map<String, dynamic> json) => RoomDto._(json);

  final Map<String, dynamic> _json;

  RoomTier toEntity() {
    return RoomTier(
      id: (_json['id'] as num).toInt(),
      roomType: _json['room_type'] as String,
      pricePerNight: asDouble(_json['price_per_night']) ?? 0,
      description: asNonEmptyString(_json['description']),
      includedServices: asNonEmptyString(_json['included_services']),
    );
  }
}

class RoomUnitDto {
  const RoomUnitDto._(this._json);

  factory RoomUnitDto.fromJson(Map<String, dynamic> json) =>
      RoomUnitDto._(json);

  final Map<String, dynamic> _json;

  RoomUnitInfo toEntity() {
    return RoomUnitInfo(
      id: (_json['id'] as num).toInt(),
      roomId: (_json['room_id'] as num).toInt(),
      unitCode: _json['unit_code'] as String,
    );
  }
}

class RoomBlockDto {
  const RoomBlockDto._(this._json);

  factory RoomBlockDto.fromJson(Map<String, dynamic> json) =>
      RoomBlockDto._(json);

  final Map<String, dynamic> _json;

  RoomBlockInfo toEntity() {
    return RoomBlockInfo(
      roomId: (_json['room_id'] as num).toInt(),
      blockedUnits: (_json['blocked_units'] as num?)?.toInt() ?? 1,
      purpose: asNonEmptyString(_json['purpose']),
    );
  }
}
