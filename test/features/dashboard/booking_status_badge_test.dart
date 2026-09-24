import 'package:flutter_test/flutter_test.dart';
import 'package:meowville/core/widgets/app_status_badge.dart';
import 'package:meowville/features/dashboard/domain/entities/booking_status.dart';
import 'package:meowville/features/dashboard/presentation/widgets/booking_status_badge.dart';

void main() {
  test('keenam status punya warna latar dan teks yang berbeda', () {
    final List<AppStatusTone> tones = BookingStatus.values
        .map(BookingStatusBadge.toneFor)
        .toList();

    expect(
      tones.map((AppStatusTone tone) => tone.surface).toSet(),
      hasLength(BookingStatus.values.length),
    );
    expect(
      tones.map((AppStatusTone tone) => tone.foreground).toSet(),
      hasLength(BookingStatus.values.length),
    );
  });

  test('semua status jadi pil berisi, tidak ada latar transparan', () {
    for (final BookingStatus status in BookingStatus.values) {
      final AppStatusTone tone = BookingStatusBadge.toneFor(status);
      expect(tone.surface.a > 0, isTrue, reason: status.wireValue);
    }
  });
}
