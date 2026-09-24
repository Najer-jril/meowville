import '../../../../core/utils/relative_date.dart';
import '../../domain/entities/daily_log_entry.dart';
import 'json_readers.dart';

class DailyLogDto {
  const DailyLogDto._(this._json);

  factory DailyLogDto.fromJson(Map<String, dynamic> json) =>
      DailyLogDto._(json);

  static const String photoBucket = 'log-photos';

  final Map<String, dynamic> _json;

  DailyLogEntry toEntity(PublicUrlResolver resolveUrl) {
    return DailyLogEntry(
      id: _json['id'] as String,
      bookingId: _json['booking_id'] as String,
      logDate: parseDateOnly(_json['log_date'] as String),
      createdAt: _json['created_at'] == null
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : parseServerTimestamp(_json['created_at'] as String),
      eatingTime: _hourMinute(_json['eating_time']),
      mood: asNonEmptyString(_json['pet_mood']),
      note: asNonEmptyString(_json['note']),
      photoUrl: photoUrlFor(resolveUrl, photoBucket, _json['photo_url']),
      authorName: asNonEmptyString(asMap(_json['author'])?['name']),
    );
  }

  static String? _hourMinute(Object? value) {
    final String? raw = asNonEmptyString(value);
    if (raw == null) {
      return null;
    }
    return raw.length >= 5 ? raw.substring(0, 5) : raw;
  }
}
