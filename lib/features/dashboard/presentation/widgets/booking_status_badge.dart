import 'package:flutter/widgets.dart';

import '../../../../core/widgets/app_status_badge.dart';
import '../../domain/entities/booking_status.dart';

class BookingStatusBadge extends StatelessWidget {
  const BookingStatusBadge({super.key, required this.status});

  final BookingStatus status;

  static String labelFor(BookingStatus status) => switch (status) {
    BookingStatus.pending => 'Menunggu',
    BookingStatus.confirmed => 'Dikonfirmasi',
    BookingStatus.rejected => 'Ditolak',
    BookingStatus.checkedIn => 'Sedang Menginap',
    BookingStatus.checkedOut => 'Selesai',
    BookingStatus.cancelled => 'Dibatalkan',
  };

  static AppStatusTone toneFor(BookingStatus status) => switch (status) {
    BookingStatus.pending => AppStatusTone.menunggu,
    BookingStatus.confirmed => AppStatusTone.disetujui,
    BookingStatus.rejected => AppStatusTone.ditolak,
    BookingStatus.checkedIn => AppStatusTone.menginap,
    BookingStatus.checkedOut => AppStatusTone.selesai,
    BookingStatus.cancelled => AppStatusTone.dibatalkan,
  };

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(label: labelFor(status), tone: toneFor(status));
  }
}
