import 'package:flutter/material.dart';

import '../../../../core/utils/relative_date.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../domain/entities/admin_booking.dart';
import '../../domain/entities/booking_decision.dart';

String decisionLabel(BookingDecision decision) => switch (decision) {
  BookingDecision.approve => 'Setujui',
  BookingDecision.reject => 'Tolak',
  BookingDecision.cancel => 'Batalkan Reservasi',
};

String decisionDoneMessage(BookingDecision decision, String petName) =>
    switch (decision) {
      BookingDecision.approve => 'Reservasi $petName disetujui.',
      BookingDecision.reject => 'Reservasi $petName ditolak.',
      BookingDecision.cancel => 'Reservasi $petName dibatalkan.',
    };

Future<bool> confirmBookingDecision(
  BuildContext context, {
  required AdminBooking booking,
  required BookingDecision decision,
}) {
  final String stay =
      '${stayRange(booking.checkin, booking.checkout)} di kamar '
      '${booking.roomType}';
  final (String title, String body, String confirmLabel) = switch (decision) {
    BookingDecision.approve => (
      'Setujui reservasi ${booking.petName}?',
      'Reservasi milik ${booking.ownerName} untuk $stay akan dikonfirmasi.',
      'Ya, setujui',
    ),
    BookingDecision.reject => (
      'Tolak reservasi ${booking.petName}?',
      'Reservasi milik ${booking.ownerName} untuk $stay akan ditolak. '
          'Penolakan tidak bisa diurungkan dari aplikasi.',
      'Ya, tolak',
    ),
    BookingDecision.cancel => (
      'Batalkan reservasi ${booking.petName}?',
      'Reservasi milik ${booking.ownerName} untuk $stay sudah '
          'dikonfirmasi. Setelah dibatalkan, kamarnya kembali tersedia '
          'dan pembatalan tidak bisa diurungkan dari aplikasi.',
      'Ya, batalkan',
    ),
  };
  return showAppConfirmDialog(
    context,
    title: title,
    body: body,
    confirmLabel: confirmLabel,
    isDestructive: decision != BookingDecision.approve,
  );
}
