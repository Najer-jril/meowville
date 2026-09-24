class RoomTier {
  const RoomTier({
    required this.id,
    required this.roomType,
    required this.pricePerNight,
    this.description,
    this.includedServices,
  });

  final int id;
  final String roomType;
  final double pricePerNight;
  final String? description;
  final String? includedServices;

  List<String> get includedServiceList {
    final String raw = includedServices ?? '';
    return raw
        .split(RegExp(r'[,\n;]'))
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
