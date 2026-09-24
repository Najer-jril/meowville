abstract final class AdminPawrentRoutes {
  static const String list = '/admin/pawrent';
  static const String detailParam = 'ownerId';
  static const String bookingSegment = 'reservasi';

  static String detail(String ownerId) => '$list/$ownerId';

  static String booking(String ownerId, String bookingId) =>
      '${detail(ownerId)}/$bookingSegment/$bookingId';
}
