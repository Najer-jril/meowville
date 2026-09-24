import '../../../../core/utils/relative_date.dart';
import 'room_type.dart';

enum RoomField { type, includedServices, price, units }

class RoomDraft {
  const RoomDraft({
    required this.type,
    required this.description,
    required this.includedServices,
    required this.priceText,
    required this.unitCount,
    this.minUnits = 1,
  });

  final RoomType? type;
  final String description;
  final String includedServices;
  final String priceText;
  final int unitCount;
  final int minUnits;

  double? get price => double.tryParse(priceText.trim());

  Map<RoomField, String> validate() {
    final double? parsed = price;
    return <RoomField, String>{
      if (type == null) RoomField.type: 'Pilih tipe kamar.',
      if (includedServices.trim().isEmpty)
        RoomField.includedServices: 'Isi paket layanan bawaan tier ini.',
      if (priceText.trim().isEmpty)
        RoomField.price: 'Isi harga per malam.'
      else if (parsed == null || parsed < 0)
        RoomField.price: 'Harga harus berupa angka rupiah.',
      if (unitCount < 1)
        RoomField.units: 'Tipe kamar butuh minimal 1 unit.'
      else if (unitCount < minUnits)
        RoomField.units:
            'Tidak bisa kurang dari $minUnits, jumlah reservasi aktif.',
    };
  }
}

enum BlockField { room, dates, units, purpose }

class RoomBlockDraft {
  const RoomBlockDraft({
    required this.roomId,
    required this.dateStart,
    required this.dateEnd,
    required this.blockedUnits,
    required this.purpose,
    required this.maxUnits,
    required this.today,
  });

  static const int purposeMaxLength = 100;

  final int? roomId;
  final DateTime? dateStart;
  final DateTime? dateEnd;
  final int blockedUnits;
  final String purpose;
  final int maxUnits;
  final DateTime today;

  Map<BlockField, String> validate() {
    final DateTime? start = dateStart;
    final DateTime? end = dateEnd;
    return <BlockField, String>{
      if (roomId == null) BlockField.room: 'Pilih tipe kamar.',
      if (start == null || end == null)
        BlockField.dates: 'Pilih tanggal mulai dan selesai.'
      else if (end.isBefore(start))
        BlockField.dates: 'Tanggal selesai tidak boleh sebelum tanggal mulai.'
      else if (end.isBefore(dateOnly(today)))
        BlockField.dates: 'Rentang ini sudah lewat.',
      if (blockedUnits < 1 || blockedUnits > maxUnits)
        BlockField.units: 'Jumlah unit harus 1 sampai $maxUnits.',
      if (purpose.trim().length > purposeMaxLength)
        BlockField.purpose: 'Keperluan maksimal $purposeMaxLength karakter.',
    };
  }
}
