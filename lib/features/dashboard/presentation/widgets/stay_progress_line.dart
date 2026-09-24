import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/booking_status.dart';
import '../../domain/entities/booking_summary.dart';

class StayProgressLine extends StatelessWidget {
  const StayProgressLine({
    super.key,
    required this.booking,
    required this.today,
  });

  final BookingSummary booking;
  final DateTime today;

  static String? textFor(BookingSummary booking, DateTime today) {
    if (booking.status != BookingStatus.checkedIn) {
      return null;
    }
    final int day = booking.stayDay(today);
    if (day > booking.nights) {
      return 'Lewat jadwal check-out';
    }
    return 'Hari ke-${day < 1 ? 1 : day} dari ${booking.nights}';
  }

  @override
  Widget build(BuildContext context) {
    final String? text = textFor(booking, today);
    if (text == null) {
      return const SizedBox.shrink();
    }
    return Text(
      text,
      style: AppTypography.labelMd.copyWith(
        color: AppColors.brandTerracottaPressed,
      ),
    );
  }
}
