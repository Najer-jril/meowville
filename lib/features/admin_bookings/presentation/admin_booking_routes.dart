abstract final class AdminBookingRoutes {
  static const String list = '/admin/reservasi';
  static const String detailParam = 'bookingId';

  static String detail(String bookingId) => '$list/$bookingId';
}
