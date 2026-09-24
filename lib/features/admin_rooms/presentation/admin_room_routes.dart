abstract final class AdminRoomRoutes {
  static const String list = '/admin/kamar';
  static const String createSegment = 'baru';
  static const String create = '$list/$createSegment';
  static const String editParam = 'roomId';

  static String edit(int roomId) => '$list/$roomId';
}
