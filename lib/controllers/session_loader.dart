import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../utils/clock.dart';
import 'addon_controller.dart';
import 'booking_controller.dart';
import 'daily_report_controller.dart';
import 'pet_controller.dart';
import 'reservation_controller.dart';
import 'room_controller.dart';
import 'user_controller.dart';

/// mulai load data yang dibaca halaman utama sesuai role. Tidak di-await, jadi navigasi langsung jalan dan layar menampilkan state loading.
void loadSessionData(BuildContext context, AppUser user) {
  final rooms = context.read<RoomController>();
  final addons = context.read<AddonController>();
  final reports = context.read<DailyReportController>();
  switch (user.role) {
    case UserRole.owner:
      context.read<PetController>().load(user.id);
      context.read<BookingController>().load(user.id);
      rooms.load();
      addons.load();
      reports.load();
    case UserRole.admin:
      context.read<ReservationController>().load();
      context.read<UserController>().load();
      rooms.load(userId: user.id, withBlocks: true);
      rooms.loadAvailability(
        Clock.today(),
        Clock.today().add(const Duration(days: 41)),
      );
      addons.load();
      reports.load();
    case UserRole.sitter:
      context.read<ReservationController>().load();
      reports.load();
  }
}

/// delete data semua akun supaya login berikutnya tidak melihat data lama.
void resetSessionData(BuildContext context) {
  context.read<PetController>().reset();
  context.read<BookingController>().reset();
  context.read<RoomController>().reset();
  context.read<AddonController>().reset();
  context.read<ReservationController>().reset();
  context.read<DailyReportController>().reset();
  context.read<UserController>().reset();
}
