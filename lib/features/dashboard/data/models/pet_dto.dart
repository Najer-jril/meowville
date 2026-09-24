import '../../domain/entities/pet_summary.dart';
import 'json_readers.dart';

class PetDto {
  const PetDto._(this._json);

  factory PetDto.fromJson(Map<String, dynamic> json) => PetDto._(json);

  static const String photoBucket = 'pet-photos';

  final Map<String, dynamic> _json;

  PetSummary toEntity(PublicUrlResolver resolveUrl) {
    return PetSummary(
      id: _json['id'] as String,
      name: _json['pet_name'] as String,
      breed: (_json['breed'] as String?) ?? '',
      sex: asNonEmptyString(_json['sex']),
      weightKg: asDouble(_json['weight_kg']),
      photoUrl: photoUrlFor(resolveUrl, photoBucket, _json['photo_url']),
    );
  }
}
