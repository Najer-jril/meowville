library;

/// ubah kolom `date` Postgres jadi tanggal lokal (tanpa jam).
DateTime _date(Object? v) => DateTime.parse(v as String);

/// ubah tanggal jadi format untuk kolom `date` Postgres.
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

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
    required this.role,
    required this.joinedAt,
    this.photo,
  });

  /// 1 baris dari tabel public.profiles.
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: UserRole.values.byName(json['role'] as String),
    joinedAt: DateTime.parse(json['joined_at'] as String).toLocal(),
    photo: json['photo'] as String?,
  );

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime joinedAt;
  final String? photo;

  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();
  String get firstName => name.split(' ').first;

  @override
  bool operator ==(Object other) => other is AppUser && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class Cat {
  Cat({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.weightKg,
    this.breed = '',
    this.photo,
    this.deleted = false,
  });

  factory Cat.fromJson(Map<String, dynamic> json) => Cat(
    id: json['id'] as int,
    ownerId: json['owner_id'] as String,
    name: json['name'] as String,
    breed: json['breed'] as String? ?? '',
    weightKg: (json['weight_kg'] as num).toDouble(),
    photo: json['photo'] as String?,
    deleted: json['deleted'] as bool? ?? false,
  );

  final int id;
  final String ownerId;
  final String name;
  final String breed;
  final double weightKg;
  final String? photo;
  final bool deleted;

  String get breedLabel => breed.isEmpty ? 'Ras tidak diketahui' : breed;

  String get weightLabel =>
      '${weightKg.toString().replaceAll('.', ',').replaceAll(RegExp(r',0$'), '')} kg';

  @override
  bool operator ==(Object other) => other is Cat && other.id == id;

  @override
  int get hashCode => id.hashCode;
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

  factory RoomType.fromJson(Map<String, dynamic> json) => RoomType(
    id: json['id'] as int,
    name: json['name'] as String,
    prefix: json['prefix'] as String,
    description: json['description'] as String? ?? '',
    price: json['price'] as int,
    unitCount: json['unit_count'] as int,
    facilities: List<String>.from(json['facilities'] as List),
    packages: List<String>.from(json['packages'] as List),
    photo: json['photo'] as String?,
    active: json['active'] as bool,
  );

  /// 0 kalau tipe kamar belum disimpan.
  final int id;
  final String name;
  final String prefix;
  final String description;
  final int price;
  final int unitCount;
  final List<String> facilities;
  final List<String> packages;
  final String? photo;
  final bool active;

  List<String> get units => List.generate(unitCount, (i) => '$prefix${i + 1}');

  Map<String, dynamic> toJson() => {
    'name': name,
    'prefix': prefix,
    'description': description,
    'price': price,
    'unit_count': unitCount,
    'facilities': facilities,
    'packages': packages,
    'photo': photo,
    'active': active,
  };

  RoomType copyWith({
    String? name,
    String? description,
    int? price,
    int? unitCount,
    List<String>? facilities,
    List<String>? packages,
    String? photo,
    bool? active,
  }) => RoomType(
    id: id,
    name: name ?? this.name,
    prefix: prefix,
    description: description ?? this.description,
    price: price ?? this.price,
    unitCount: unitCount ?? this.unitCount,
    facilities: facilities ?? this.facilities,
    packages: packages ?? this.packages,
    photo: photo ?? this.photo,
    active: active ?? this.active,
  );

  @override
  bool operator ==(Object other) => other is RoomType && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class Addon {
  Addon({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.active = true,
  });

  factory Addon.fromJson(Map<String, dynamic> json) => Addon(
    id: json['id'] as int,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    price: json['price'] as int,
    active: json['active'] as bool,
  );

  /// 0 kalau addon belum disimpan.
  final int id;
  final String name;
  final String description;
  final int price;
  final bool active;

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'price': price,
    'active': active,
  };

  @override
  bool operator ==(Object other) => other is Addon && other.id == id;

  @override
  int get hashCode => id.hashCode;
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
  static ReservationStatus parse(String key) =>
      ReservationStatus.values.firstWhere((s) => s.key == key);

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
    required this.roomPrice,
    required this.status,
    this.addons = const [],
    this.unit,
    this.paymentProof,
    this.adminNote,
  });

  /// query select PostgREST beserta semua relasi yang dipakai layar
  static const select =
      '*,cat:cats(*),owner:profiles(*),room_type:room_types(*),'
      'addons:reservation_addons(price,addon:addons(*))';

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
    id: json['id'] as int,
    cat: Cat.fromJson(json['cat'] as Map<String, dynamic>),
    owner: AppUser.fromJson(json['owner'] as Map<String, dynamic>),
    roomType: RoomType.fromJson(json['room_type'] as Map<String, dynamic>),
    checkIn: _date(json['check_in']),
    checkOut: _date(json['check_out']),
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    roomPrice: json['room_price'] as int,
    status: ReservationStatusX.parse(json['status'] as String),
    addons: [
      for (final row in json['addons'] as List)
        Addon.fromJson({
          ...row['addon'] as Map<String, dynamic>,
          'price': row['price'],
        }),
    ],
    unit: json['unit'] as String?,
    paymentProof: json['payment_proof'] as String?,
    adminNote: json['admin_note'] as String?,
  );

  final int id;
  final Cat cat;
  final AppUser owner;
  final RoomType roomType;
  final DateTime checkIn;
  final DateTime checkOut;
  final DateTime createdAt;

  /// harga per malam saat reservasi dibuat
  final int roomPrice;
  final ReservationStatus status;

  /// daftar addon dengan harga yang berlaku saat booking
  final List<Addon> addons;
  final String? unit;
  final String? paymentProof;
  final String? adminNote;

  int get nights => checkOut.difference(checkIn).inDays;
  int get roomTotal => roomPrice * nights;
  int get addonTotal => addons.fold(0, (sum, a) => sum + a.price);
  int get total => roomTotal + addonTotal;

  bool coversNight(DateTime day) =>
      !day.isBefore(checkIn) && day.isBefore(checkOut);

  bool overlaps(DateTime start, DateTime endInclusive) =>
      checkIn.isBefore(endInclusive.add(const Duration(days: 1))) &&
      checkOut.isAfter(start);

  @override
  bool operator ==(Object other) => other is Reservation && other.id == id;

  @override
  int get hashCode => id.hashCode;
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

  factory UnitBlock.fromJson(Map<String, dynamic> json) => UnitBlock(
    id: json['id'] as int,
    roomType: RoomType.fromJson(json['room_type'] as Map<String, dynamic>),
    unit: json['unit'] as String,
    start: _date(json['start_date']),
    end: _date(json['end_date']),
    reason: json['reason'] as String? ?? '',
  );

  final int id;
  final RoomType roomType;
  final String unit;
  final DateTime start;
  final DateTime end;
  final String reason;

  bool covers(DateTime day) => !day.isBefore(start) && !day.isAfter(end);

  @override
  bool operator ==(Object other) => other is UnitBlock && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class DayAvailability {
  const DayAvailability({
    required this.roomTypeId,
    required this.day,
    required this.units,
    required this.occupied,
    required this.pending,
    required this.blocked,
  });

  factory DayAvailability.fromJson(Map<String, dynamic> json) =>
      DayAvailability(
        roomTypeId: json['room_type_id'] as int,
        day: _date(json['day']),
        units: json['units'] as int,
        occupied: json['occupied'] as int,
        pending: json['pending'] as int,
        blocked: json['blocked'] as int,
      );

  final int roomTypeId;
  final DateTime day;
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
    this.reporterName = '',
  });

  static const select =
      '*,reporter:profiles(*),reservation:reservations(${Reservation.select})';

  factory DailyReport.fromJson(Map<String, dynamic> json) => DailyReport(
    id: json['id'] as int,
    reservation: Reservation.fromJson(
      json['reservation'] as Map<String, dynamic>,
    ),
    reporter: json['reporter'] == null
        ? null
        : AppUser.fromJson(json['reporter'] as Map<String, dynamic>),
    time: DateTime.parse(json['time'] as String).toLocal(),
    food: json['food'] as String,
    drink: json['drink'] as String,
    mood: json['mood'] as String,
    note: json['note'] as String? ?? '',
    photo: json['photo'] as String?,
    reporterName: json['reporter_name'] as String? ?? '',
  );

  static const foodOptions = ['Habis', 'Sedikit', 'Gamau makan'];
  static const drinkOptions = ['Normal', 'Sedikit', 'Banyak'];
  static const moodOptions = ['Aktif', 'Kalem', 'Agresif', 'Sakit'];

  final int id;
  final Reservation reservation;

  /// null untuk owner (tidak boleh membaca profil staf) dan kalau akun staf
  /// sudah dihapus. Nama pelapor tetap ada di [reporterName].
  final AppUser? reporter;
  final String reporterName;

  String get reporterFullName =>
      reporter?.name ?? (reporterName.isEmpty ? 'Staff' : reporterName);
  String get reporterFirstName =>
      reporter?.firstName ??
      (reporterName.isEmpty ? 'staff' : reporterName.split(' ').first);
  final DateTime time;
  final String food;
  final String drink;
  final String mood;
  final String note;
  final String? photo;

  @override
  bool operator ==(Object other) => other is DailyReport && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class ReportRow {
  ReportRow(this.roomType);

  final RoomType roomType;
  int bookings = 0;
  int revenue = 0;
}

class ReportData {
  const ReportData({
    required this.rows,
    required this.bookings,
    required this.revenue,
    required this.avgNights,
  });

  final List<ReportRow> rows;
  final int bookings;
  final int revenue;
  final double avgNights;

  bool get isEmpty => bookings == 0;
}

/// Baris tunggal tabel public.app_settings. Diubah admin lewat Supabase
/// Dashboard, jadi data bank dan kontak bisa diganti tanpa rilis ulang.
class AppSettings {
  const AppSettings({
    required this.demoMode,
    required this.bankName,
    required this.bankAccount,
    required this.bankHolder,
    required this.supportEmail,
  });

  /// Dipakai sebelum data dari server termuat atau saat offline.
  static const fallback = AppSettings(
    demoMode: true,
    bankName: 'Bank Demo',
    bankAccount: '0000 0000 00',
    bankHolder: 'Meowville Demo',
    supportEmail: 'meowville@najer.dev',
  );

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    demoMode: json['demo_mode'] as bool,
    bankName: json['bank_name'] as String,
    bankAccount: json['bank_account'] as String,
    bankHolder: json['bank_holder'] as String,
    supportEmail: json['support_email'] as String,
  );

  final bool demoMode;
  final String bankName;
  final String bankAccount;
  final String bankHolder;
  final String supportEmail;
}
