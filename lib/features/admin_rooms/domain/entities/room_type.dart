enum RoomType {
  standard('Standard', 'STD-'),
  deluxe('Deluxe', 'DLX-'),
  suite('Suite', 'STE-');

  const RoomType(this.wireValue, this.unitPrefix);

  final String wireValue;
  final String unitPrefix;

  static RoomType? fromWireValue(String value) {
    for (final RoomType type in RoomType.values) {
      if (type.wireValue == value) {
        return type;
      }
    }
    return null;
  }
}
