library;

enum UserRole { owner, admin, sitter }

extension UserRoleX on UserRole {
  String get key => switch (this) {
    UserRole.owner => 'owner',
    UserRole.admin => 'admin',
    UserRole.sitter => 'sitter',
  };
}

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.joinedAt,
    this.photo,
  });

  final String id;
  String name;
  final String email;
  String phone;
  final UserRole role;
  final DateTime joinedAt;
  final String? photo;

  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();
  String get firstName => name.split(' ').first;
}

class Cat {
  Cat({
    required this.id,
    required this.owner,
    required this.name,
    required this.weightKg,
    this.breed = '',
    this.photo,
    this.birthDate,
  });

  final String id;
  final AppUser owner;
  String name;

  String breed;
  double weightKg;
  String? photo;
  DateTime? birthDate;

  bool deleted = false;

  String get breedLabel => breed.isEmpty ? 'Ras tidak diketahui' : breed;

  String get weightLabel =>
      '${weightKg.toString().replaceAll('.', ',').replaceAll(RegExp(r',0$'), '')} kg';

  String? ageLabel(DateTime today) {
    final b = birthDate;
    if (b == null) return null;
    var months = (today.year - b.year) * 12 + today.month - b.month;
    if (today.day < b.day) months--;
    if (months < 1) return 'Kurang dari 1 bulan';
    final y = months ~/ 12;
    final m = months % 12;
    return [if (y > 0) '$y tahun', if (m > 0) '$m bulan'].join(' ');
  }
}

class RoomType {
  RoomType({
    required this.id,
    required this.name,
    required this.prefix,
    required this.description,
    required this.price,
    required this.unitCount,
    required this.facilities,
    required this.packages,
    this.photo,
    this.active = true,
  });

  final String id;
  String name;
  final String prefix;
  String description;
  int price;
  int unitCount;
  List<String> facilities;
  List<String> packages;
  String? photo;
  bool active;

  List<String> get units => List.generate(unitCount, (i) => '$prefix${i + 1}');
}

class Addon {
  Addon({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.active = true,
  });

  final String id;
  String name;
  String description;
  int price;
  bool active;
}

enum ReservationStatus {
  pending,
  confirmed,
  checkedIn,
  completed,
  rejected,
  cancelled,
}

extension ReservationStatusX on ReservationStatus {
  String get key => switch (this) {
    ReservationStatus.pending => 'pending',
    ReservationStatus.confirmed => 'confirmed',
    ReservationStatus.checkedIn => 'checked_in',
    ReservationStatus.completed => 'completed',
    ReservationStatus.rejected => 'rejected',
    ReservationStatus.cancelled => 'cancelled',
  };

  bool get holdsUnit =>
      this == ReservationStatus.confirmed ||
      this == ReservationStatus.checkedIn;

  bool get isActive => this == ReservationStatus.pending || holdsUnit;

  bool get countsAsRevenue =>
      this == ReservationStatus.confirmed ||
      this == ReservationStatus.checkedIn ||
      this == ReservationStatus.completed;
}

class Reservation {
  Reservation({
    required this.id,
    required this.cat,
    required this.owner,
    required this.roomType,
    required this.checkIn,
    required this.checkOut,
    required this.createdAt,
    this.addons = const [],
    this.status = ReservationStatus.pending,
    this.unit,
    this.paymentProof,
    this.adminNote,
  });

  final String id;
  final Cat cat;
  final AppUser owner;
  final RoomType roomType;
  final DateTime checkIn;
  final DateTime checkOut;
  final DateTime createdAt;
  final List<Addon> addons;
  ReservationStatus status;
  String? unit;
  String? paymentProof;
  String? adminNote;

  int get nights => checkOut.difference(checkIn).inDays;
  int get roomTotal => roomType.price * nights;
  int get addonTotal => addons.fold(0, (sum, a) => sum + a.price);
  int get total => roomTotal + addonTotal;

  bool coversNight(DateTime day) =>
      !day.isBefore(checkIn) && day.isBefore(checkOut);

  bool overlaps(DateTime start, DateTime endInclusive) =>
      checkIn.isBefore(endInclusive.add(const Duration(days: 1))) &&
      checkOut.isAfter(start);
}

class UnitBlock {
  UnitBlock({
    required this.id,
    required this.roomType,
    required this.unit,
    required this.start,
    required this.end,
    required this.reason,
  });

  final String id;
  final RoomType roomType;
  final String unit;
  final DateTime start;

  final DateTime end;
  final String reason;

  bool covers(DateTime day) => !day.isBefore(start) && !day.isAfter(end);
}

class DayAvailability {
  const DayAvailability({
    required this.units,
    required this.occupied,
    required this.pending,
    required this.blocked,
  });

  final int units;
  final int occupied;
  final int pending;
  final int blocked;

  int get remaining {
    final r = units - occupied - pending - blocked;
    return r < 0 ? 0 : r;
  }
}

class DailyReport {
  DailyReport({
    required this.id,
    required this.reservation,
    required this.reporter,
    required this.time,
    required this.food,
    required this.drink,
    required this.mood,
    this.note = '',
    this.photo,
  });

  static const foodOptions = ['Habis', 'Sedikit', 'Gamau makan'];
  static const drinkOptions = ['Normal', 'Sedikit', 'Banyak'];
  static const moodOptions = ['Aktif', 'Kalem', 'Agresif', 'Sakit'];

  final String id;
  final Reservation reservation;
  final AppUser reporter;
  final DateTime time;
  final String food;
  final String drink;
  final String mood;
  final String note;
  final String? photo;
}
