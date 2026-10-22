import 'package:flutter/foundation.dart';

import '../theme/app_assets.dart';
import '../utils/format.dart';
import 'models.dart';

class AdminStore extends ChangeNotifier {
  AdminStore() {
    _seed();
  }

  final DateTime today = DateTime(2026, 10, 16);
  DateTime get now => today.add(const Duration(hours: 10));

  final AppUser currentAdmin = AppUser(
    id: 'u-admin',
    name: 'Admin Meowville',
    email: 'admin@meowville.id',
    phone: '0811-0000-1111',
    role: UserRole.admin,
    joinedAt: DateTime(2026, 9, 1),
  );

  final List<AppUser> users = [];
  final List<RoomType> roomTypes = [];
  final List<Addon> addons = [];
  final List<Reservation> reservations = [];
  final List<UnitBlock> blocks = [];
  final List<DailyReport> reports = [];
  final List<Cat> cats = [];

  AppUser get currentSitter => users.firstWhere((u) => u.id == 'u-mahar');

  int _seq = 100;
  String _nextId(String prefix) => '$prefix-${_seq++}';

  List<Reservation> get pending =>
      reservations.where((r) => r.status == ReservationStatus.pending).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Reservation> get latest =>
      [...reservations]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<RoomType> get activeRoomTypes =>
      roomTypes.where((t) => t.active).toList();

  List<UnitBlock> blocksFor(RoomType type) =>
      blocks.where((b) => b.roomType == type && !b.end.isBefore(today)).toList()
        ..sort((a, b) => a.start.compareTo(b.start));

  DayAvailability availability(RoomType type, DateTime day) {
    var occupied = 0;
    var pendingCount = 0;
    for (final r in reservations) {
      if (r.roomType != type || !r.coversNight(day)) continue;
      if (r.status.holdsUnit) occupied++;
      if (r.status == ReservationStatus.pending) pendingCount++;
    }
    final blocked = blocks
        .where((b) => b.roomType == type && b.covers(day))
        .length;
    return DayAvailability(
      units: type.unitCount,
      occupied: occupied,
      pending: pendingCount,
      blocked: blocked,
    );
  }

  List<String> freeUnits(
    RoomType type,
    DateTime start,
    DateTime endExclusive, {
    Reservation? ignore,
  }) {
    final lastNight = endExclusive.subtract(const Duration(days: 1));
    return type.units.where((unit) {
      final busy = reservations.any(
        (r) =>
            r != ignore &&
            r.unit == unit &&
            r.roomType == type &&
            r.status.holdsUnit &&
            r.overlaps(start, lastNight),
      );
      final blocked = blocks.any(
        (b) =>
            b.roomType == type &&
            b.unit == unit &&
            !b.start.isAfter(lastNight) &&
            !b.end.isBefore(start),
      );
      return !busy && !blocked;
    }).toList();
  }

  int activeReservationCount(RoomType type) => reservations
      .where(
        (r) =>
            r.roomType == type &&
            (r.status == ReservationStatus.pending || r.status.holdsUnit),
      )
      .length;

  List<Reservation> checkInsToday() =>
      reservations.where((r) => _sameDay(r.checkIn, today)).where((r) {
        return r.status.holdsUnit;
      }).toList();

  List<Reservation> checkOutsToday() => reservations
      .where(
        (r) =>
            _sameDay(r.checkOut, today) &&
            (r.status == ReservationStatus.checkedIn ||
                r.status == ReservationStatus.completed),
      )
      .toList();

  List<Reservation> get staying => reservations
      .where((r) => r.status == ReservationStatus.checkedIn)
      .toList();

  int get totalActiveUnits =>
      activeRoomTypes.fold(0, (sum, t) => sum + t.unitCount);

  List<Reservation> get awaitingCheckIn =>
      reservations
          .where(
            (r) =>
                r.status == ReservationStatus.confirmed &&
                !r.checkIn.isAfter(today),
          )
          .toList()
        ..sort((a, b) => a.checkIn.compareTo(b.checkIn));

  List<Reservation> get stayingNotLeaving =>
      staying.where((r) => r.checkOut.isAfter(today)).toList()
        ..sort((a, b) => a.checkOut.compareTo(b.checkOut));

  List<Reservation> get dueCheckOut =>
      staying.where((r) => !r.checkOut.isAfter(today)).toList();

  DailyReport? reportToday(Reservation r) {
    final list =
        reports
            .where((d) => d.reservation == r && _sameDay(d.time, today))
            .toList()
          ..sort((a, b) => b.time.compareTo(a.time));
    return list.isEmpty ? null : list.first;
  }

  List<DailyReport> get reportHistory =>
      [...reports]..sort((a, b) => b.time.compareTo(a.time));

  AppUser get currentOwner => users.firstWhere((u) => u.id == 'u-najer');

  List<Cat> catsOf(AppUser owner) =>
      cats.where((c) => c.owner == owner && !c.deleted).toList();

  List<Reservation> reservationsOf(AppUser owner) =>
      latest.where((r) => r.owner == owner).toList();

  Reservation? clashFor(Cat cat, DateTime start, DateTime endExclusive) {
    for (final r in reservations) {
      if (r.cat == cat &&
          r.status.isActive &&
          r.checkIn.isBefore(endExclusive) &&
          r.checkOut.isAfter(start)) {
        return r;
      }
    }
    return null;
  }

  Reservation? activeReservationOf(Cat cat) {
    final list =
        reservations.where((r) => r.cat == cat && r.status.isActive).toList()
          ..sort((a, b) => a.checkIn.compareTo(b.checkIn));
    return list.isEmpty ? null : list.first;
  }

  int remainingFor(RoomType type, DateTime start, DateTime endExclusive) {
    var min = type.unitCount;
    for (
      var d = start;
      d.isBefore(endExclusive);
      d = d.add(const Duration(days: 1))
    ) {
      final left = availability(type, d).remaining;
      if (left < min) min = left;
    }
    return min;
  }

  DateTime proofDeadline(Reservation r) =>
      r.createdAt.add(const Duration(hours: 24));

  Reservation createReservation({
    required Cat cat,
    required RoomType type,
    required DateTime checkIn,
    required DateTime checkOut,
    required List<Addon> addons,
    String? paymentProof,
  }) {
    final r = Reservation(
      id: _nextId('r'),
      cat: cat,
      owner: cat.owner,
      roomType: type,
      checkIn: checkIn,
      checkOut: checkOut,
      createdAt: now,
      addons: addons,
      paymentProof: paymentProof,
    );
    reservations.add(r);
    notifyListeners();
    return r;
  }

  void uploadProof(Reservation r, String path) {
    r.paymentProof = path;
    notifyListeners();
  }

  Cat addCat({
    required AppUser owner,
    required String name,
    required String breed,
    required double weightKg,
    String? photo,
  }) {
    final cat = Cat(
      owner: owner,
      name: name,
      breed: breed,
      weightKg: weightKg,
      photo: photo,
    );
    cats.add(cat);
    notifyListeners();
    return cat;
  }

  void updateCat(
    Cat cat, {
    required String name,
    required String breed,
    required double weightKg,
    String? photo,
  }) {
    cat
      ..name = name
      ..breed = breed
      ..weightKg = weightKg
      ..photo = photo;
    notifyListeners();
  }

  bool deleteCat(Cat cat) {
    if (activeReservationOf(cat) != null) return false;
    cat.deleted = true;
    notifyListeners();
    return true;
  }

  void updateProfile(
    AppUser user, {
    required String name,
    required String phone,
  }) {
    user
      ..name = name
      ..phone = phone;
    notifyListeners();
  }

  ReportData report(DateTime start, DateTime end) {
    final rows = <RoomType, ReportRow>{};
    var nights = 0;
    final list = reservations.where(
      (r) =>
          r.status.countsAsRevenue &&
          !r.checkIn.isBefore(start) &&
          !r.checkIn.isAfter(end),
    );
    for (final r in list) {
      final row = rows.putIfAbsent(r.roomType, () => ReportRow(r.roomType));
      row.bookings++;
      row.revenue += r.total;
      nights += r.nights;
    }
    final sorted = rows.values.toList()
      ..sort((a, b) => b.bookings.compareTo(a.bookings));
    final count = list.length;
    return ReportData(
      rows: sorted,
      bookings: count,
      revenue: sorted.fold(0, (sum, r) => sum + r.revenue),
      avgNights: count == 0 ? 0 : nights / count,
    );
  }

  void approve(Reservation r, String unit) {
    r
      ..status = ReservationStatus.confirmed
      ..unit = unit;
    notifyListeners();
  }

  void reject(Reservation r, String reason) {
    r
      ..status = ReservationStatus.rejected
      ..adminNote = reason;
    notifyListeners();
  }

  void cancel(Reservation r) {
    r.status = ReservationStatus.cancelled;
    notifyListeners();
  }

  void checkIn(Reservation r) {
    r.status = ReservationStatus.checkedIn;
    notifyListeners();
  }

  void checkOut(Reservation r) {
    r.status = ReservationStatus.completed;
    notifyListeners();
  }

  void addReport({
    required Reservation reservation,
    required AppUser reporter,
    required String food,
    required String drink,
    required String mood,
    String note = '',
    String? photo,
  }) {
    reports.add(
      DailyReport(
        reservation: reservation,
        reporter: reporter,
        time: now,
        food: food,
        drink: drink,
        mood: mood,
        note: note,
        photo: photo,
      ),
    );
    notifyListeners();
  }

  String? addBlock({
    required RoomType type,
    required String unit,
    required DateTime start,
    required DateTime end,
    required String reason,
  }) {
    final clash = reservations.where(
      (r) =>
          r.roomType == type &&
          r.unit == unit &&
          r.status.holdsUnit &&
          r.overlaps(start, end),
    );
    if (clash.isNotEmpty) {
      final r = clash.first;
      return 'Unit $unit punya reservasi pada '
          '${Fmt.range(r.checkIn, r.checkOut)}. '
          'Batalkan reservasinya terlebih dahulu.';
    }
    blocks.add(
      UnitBlock(
        roomType: type,
        unit: unit,
        start: start,
        end: end,
        reason: reason,
      ),
    );
    notifyListeners();
    return null;
  }

  void removeBlock(UnitBlock block) {
    blocks.remove(block);
    notifyListeners();
  }

  void setRoomTypeActive(RoomType type, bool active) {
    type.active = active;
    notifyListeners();
  }

  void saveRoomType({
    RoomType? existing,
    required String name,
    required String prefix,
    required String description,
    required int price,
    required int unitCount,
    required List<String> facilities,
    required List<String> packages,
    String? photo,
  }) {
    if (existing != null) {
      existing
        ..name = name
        ..description = description
        ..price = price
        ..unitCount = unitCount
        ..facilities = facilities
        ..packages = packages
        ..photo = photo;
    } else {
      roomTypes.add(
        RoomType(
          name: name,
          prefix: prefix,
          description: description,
          price: price,
          unitCount: unitCount,
          facilities: facilities,
          packages: packages,
          photo: photo,
        ),
      );
    }
    notifyListeners();
  }

  bool prefixTaken(String prefix, {RoomType? except}) => roomTypes.any(
    (t) => t != except && t.prefix.toUpperCase() == prefix.toUpperCase(),
  );

  void setAddonActive(Addon addon, bool active) {
    addon.active = active;
    notifyListeners();
  }

  void saveAddon({
    Addon? existing,
    required String name,
    required String description,
    required int price,
  }) {
    if (existing != null) {
      existing
        ..name = name
        ..description = description
        ..price = price;
    } else {
      addons.add(Addon(name: name, description: description, price: price));
    }
    notifyListeners();
  }

  bool emailTaken(String email) =>
      users.any((u) => u.email.toLowerCase() == email.toLowerCase());

  void addUser({
    required String name,
    required String phone,
    required String email,
    required UserRole role,
  }) {
    users.insert(
      0,
      AppUser(
        id: _nextId('u'),
        name: name,
        email: email,
        phone: phone,
        role: role,
        joinedAt: today,
      ),
    );
    notifyListeners();
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _d(int month, int day, [int hour = 0, int minute = 0]) =>
      DateTime(2026, month, day, hour, minute);

  void _seed() {
    final nazril = AppUser(
      id: 'u-nazril',
      name: 'Nazril Ilham',
      email: 'nazril.ilham@gmail.com',
      phone: '0812-3456-7890',
      role: UserRole.owner,
      joinedAt: _d(9, 3),
      photo: AppImages.userNazril,
    );
    final ilham = AppUser(
      id: 'u-ilham',
      name: 'Ilham Goodman',
      email: 'ilham.goodman@gmail.com',
      phone: '0813-2233-4455',
      role: UserRole.owner,
      joinedAt: _d(9, 8),
      photo: AppImages.userIlham,
    );
    final najer = AppUser(
      id: 'u-najer',
      name: 'Najer Pinkman',
      email: 'najer.pinkman@gmail.com',
      phone: '0857-1122-3344',
      role: UserRole.owner,
      joinedAt: _d(9, 12),
      photo: AppImages.userNajer,
    );
    final iqbal = AppUser(
      id: 'u-iqbal',
      name: 'Iqbal Salamanca',
      email: 'iqbal.salamanca@gmail.com',
      phone: '0819-7788-1200',
      role: UserRole.owner,
      joinedAt: _d(9, 14),
      photo: AppImages.userIqbal,
    );
    final shadiq = AppUser(
      id: 'u-shadiq',
      name: 'Shadiq Margolis',
      email: 'shadiq.margolis@gmail.com',
      phone: '0815-6600-4321',
      role: UserRole.owner,
      joinedAt: _d(9, 20),
      photo: AppImages.userShadiq,
    );
    final irfan = AppUser(
      id: 'u-irfan',
      name: 'Irfan Bachdim',
      email: 'irfan.bachdim@gmail.com',
      phone: '0817-4545-9090',
      role: UserRole.owner,
      joinedAt: _d(9, 22),
      photo: AppImages.userIrfan,
    );

    final mahar = AppUser(
      id: 'u-mahar',
      name: 'Mahar Uzumaki',
      email: 'mahar.sitter@meowville.id',
      phone: '0821-5566-7788',
      role: UserRole.sitter,
      joinedAt: _d(9, 2),
      photo: AppImages.userMahar,
    );
    final radit = AppUser(
      id: 'u-radit',
      name: 'Radit Adler',
      email: 'radit.sitter@meowville.id',
      phone: '0822-9900-1122',
      role: UserRole.sitter,
      joinedAt: _d(9, 2),
      photo: AppImages.userRadit,
    );
    users.addAll([
      nazril,
      ilham,
      najer,
      iqbal,
      shadiq,
      irfan,
      currentAdmin,
      mahar,
      radit,
    ]);

    final standard = RoomType(
      name: 'Standard',
      prefix: 'S',
      description:
          'Kamar nyaman untuk satu kucing dengan kasur empuk '
          'dan rak panjat kecil.',
      price: 50000,
      unitCount: 4,
      facilities: ['AC', 'Kasur empuk'],
      packages: ['Mainan', 'Laporan harian'],
      photo: AppImages.roomStandard,
    );
    final deluxe = RoomType(
      name: 'Deluxe',
      prefix: 'D',
      description:
          'Kamar luas dan sejuk khusus anabul aktif dengan area '
          'vertikal yang nyaman.',
      price: 85000,
      unitCount: 3,
      facilities: ['AC', 'Jendela besar', 'Panjat kucing'],
      packages: ['Mainan', 'Laporan harian', 'Sisir bulu'],
      photo: AppImages.roomDeluxe,
    );
    final suite = RoomType(
      name: 'Suite',
      prefix: 'ST',
      description:
          'Suite dengan jendela taman, cat tree tinggi, dan ruang '
          'bermain pribadi.',
      price: 130000,
      unitCount: 2,
      facilities: ['AC', 'Jendela taman', 'Cat tree', 'CCTV'],
      packages: ['Mainan', 'Laporan harian', 'Sisir bulu', 'Foto harian'],
      photo: AppImages.roomSuite,
    );
    final presidential = RoomType(
      name: 'Presidential',
      prefix: 'P',
      description:
          'Kamar terbesar dengan webcam 24 jam untuk dipantau '
          'pemilik.',
      price: 200000,
      unitCount: 1,
      facilities: ['AC', 'Webcam', 'Ruang bermain'],
      packages: ['Mainan', 'Laporan harian', 'Webcam 24h'],
      photo: AppImages.roomPresidential,
      active: false,
    );
    roomTypes.addAll([standard, deluxe, suite, presidential]);

    final grooming = Addon(
      name: 'Grooming Lengkap',
      description: 'Mandi, sisir, potongin kuku, bersihin telinga',
      price: 80000,
    );
    final jamur = Addon(
      name: 'Mandi Jamur',
      description: 'Perawatan khusus untuk masalah jamur kulit',
      price: 45000,
    );
    final kuku = Addon(
      name: 'Potong Kuku',
      description: 'Potong dan rapikan kuku',
      price: 25000,
    );
    final antar = Addon(
      name: 'Antar Jemput',
      description: 'Jemput dan antar kucing ke rumah',
      price: 60000,
    );
    final sisir = Addon(
      name: 'Sisir Bulu',
      description: 'Sisir dan rapikan bulu',
      price: 20000,
    );
    final catnip = Addon(
      name: 'Catnip Aromaterapi',
      description: 'Pijat dan aromaterapi untuk relaksasi',
      price: 90000,
      active: false,
    );
    addons.addAll([grooming, jamur, kuku, antar, sisir, catnip]);

    final rayquaza = Cat(
      owner: nazril,
      name: 'Rayquaza',
      breed: 'Persia',
      weightKg: 4.2,
      photo: AppImages.catRayquaza,
    );
    final arceus = Cat(
      owner: ilham,
      name: 'Arceus',
      breed: 'British Shorthair',
      weightKg: 5.1,
      photo: AppImages.catArceus,
    );
    final zekrom = Cat(
      owner: ilham,
      name: 'Zekrom',
      breed: 'British Shorthair',
      weightKg: 4.7,
      photo: AppImages.catZekrom,
    );
    final dialga = Cat(
      owner: najer,
      name: 'Dialga',
      breed: 'Domestic',
      weightKg: 3.6,
      photo: AppImages.catDialga,
    );
    final reshiram = Cat(
      owner: najer,
      name: 'Reshiram',
      breed: 'Domestic',
      weightKg: 4.4,
      photo: AppImages.catReshiram,
    );
    final palkia = Cat(
      owner: iqbal,
      name: 'Palkia',
      breed: 'Scottish Fold',
      weightKg: 4.0,
      photo: AppImages.catPalkia,
    );
    final giratina = Cat(
      owner: shadiq,
      name: 'Giratina',
      breed: 'Anggora',
      weightKg: 3.4,
      photo: AppImages.catGiratina,
    );
    final kyurem = Cat(
      owner: irfan,
      name: 'Kyurem',
      breed: 'Maine Coon',
      weightKg: 6.8,
      photo: AppImages.catKyurem,
    );
    cats.addAll([
      rayquaza,
      arceus,
      zekrom,
      dialga,
      reshiram,
      palkia,
      giratina,
      kyurem,
    ]);

    final pets = [for (final c in cats) (c, c.owner)];

    final historyTypes = [standard, standard, deluxe, standard, suite, deluxe];
    final historyAddons = [
      <Addon>[],
      [kuku],
      [grooming],
      <Addon>[],
      [sisir],
      [grooming, jamur],
    ];
    for (var i = 0; i < 45; i++) {
      final checkIn = _d(7, 22).add(Duration(days: i * 2 + i % 3));
      final checkOut = checkIn.add(Duration(days: 1 + i % 4));
      if (!checkOut.isBefore(_d(10, 13))) break;
      final type = historyTypes[i % historyTypes.length];
      final (cat, owner) = pets[i % pets.length];
      reservations.add(
        Reservation(
          id: 'r-h${(i + 1).toString().padLeft(2, '0')}',
          cat: cat,
          owner: owner,
          roomType: type,
          unit: type.units[i % type.unitCount],
          checkIn: checkIn,
          checkOut: checkOut,
          createdAt: checkIn.subtract(const Duration(days: 3)),
          addons: historyAddons[i % historyAddons.length],
          status: ReservationStatus.completed,
          paymentProof: AppImages.payment3,
        ),
      );
    }

    reservations.addAll([
      Reservation(
        id: 'r-rayquaza',
        cat: rayquaza,
        owner: nazril,
        roomType: deluxe,
        checkIn: _d(10, 17),
        checkOut: _d(10, 20),
        createdAt: now.subtract(const Duration(minutes: 40)),
        addons: [grooming, jamur],
        paymentProof: AppImages.payment1,
      ),
      Reservation(
        id: 'r-zekrom',
        cat: zekrom,
        owner: ilham,
        roomType: standard,
        checkIn: _d(10, 18),
        checkOut: _d(10, 21),
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      Reservation(
        id: 'r-reshiram',
        cat: reshiram,
        owner: najer,
        roomType: standard,
        unit: 'S2',
        checkIn: _d(10, 16),
        checkOut: _d(10, 19),
        createdAt: _d(10, 12),
        addons: [kuku],
        status: ReservationStatus.confirmed,
        paymentProof: AppImages.payment2,
      ),
      Reservation(
        id: 'r-arceus',
        cat: arceus,
        owner: ilham,
        roomType: deluxe,
        unit: 'D1',
        checkIn: _d(10, 20),
        checkOut: _d(10, 23),
        createdAt: _d(10, 13),
        addons: [kuku],
        status: ReservationStatus.confirmed,
        paymentProof: AppImages.payment1,
      ),
      Reservation(
        id: 'r-dialga',
        cat: dialga,
        owner: najer,
        roomType: standard,
        unit: 'S1',
        checkIn: _d(10, 14),
        checkOut: _d(10, 17),
        createdAt: _d(10, 10),
        addons: [sisir],
        status: ReservationStatus.checkedIn,
        paymentProof: AppImages.payment2,
      ),
      Reservation(
        id: 'r-palkia',
        cat: palkia,
        owner: iqbal,
        roomType: suite,
        unit: 'ST1',
        checkIn: _d(10, 13),
        checkOut: _d(10, 16),
        createdAt: _d(10, 8),
        addons: [grooming],
        status: ReservationStatus.checkedIn,
        paymentProof: AppImages.payment3,
      ),
      Reservation(
        id: 'r-giratina',
        cat: giratina,
        owner: shadiq,
        roomType: standard,
        checkIn: _d(10, 22),
        checkOut: _d(10, 23),
        createdAt: _d(10, 14),
        status: ReservationStatus.rejected,
        paymentProof: AppImages.payment2,
        adminNote:
            'Mohon maaf, bukti pembayaran belum sesuai nominal. '
            'Silakan ajukan ulang dengan bukti transfer yang benar.',
      ),
      Reservation(
        id: 'r-kyurem',
        cat: kyurem,
        owner: irfan,
        roomType: deluxe,
        unit: 'D2',
        checkIn: _d(10, 24),
        checkOut: _d(10, 27),
        createdAt: _d(10, 11),
        addons: [antar],
        status: ReservationStatus.cancelled,
        paymentProof: AppImages.payment1,
      ),
    ]);

    reservations.addAll([
      Reservation(
        id: 'r-kyurem-2',
        cat: kyurem,
        owner: irfan,
        roomType: suite,
        unit: 'ST2',
        checkIn: _d(10, 15),
        checkOut: _d(10, 18),
        createdAt: _d(10, 12),
        addons: [antar],
        status: ReservationStatus.confirmed,
        paymentProof: AppImages.payment1,
      ),
      Reservation(
        id: 'r-giratina-2',
        cat: giratina,
        owner: shadiq,
        roomType: deluxe,
        unit: 'D2',
        checkIn: _d(10, 15),
        checkOut: _d(10, 18),
        createdAt: _d(10, 14, 16),
        addons: [kuku],
        status: ReservationStatus.checkedIn,
        paymentProof: AppImages.payment3,
      ),
    ]);

    reservations.addAll([
      Reservation(
        id: 'r-dialga-2',
        cat: dialga,
        owner: najer,
        roomType: deluxe,
        checkIn: _d(10, 24),
        checkOut: _d(10, 27),
        createdAt: now.subtract(const Duration(hours: 3)),
        addons: [grooming],
      ),
      Reservation(
        id: 'r-reshiram-2',
        cat: reshiram,
        owner: najer,
        roomType: standard,
        checkIn: _d(11, 2),
        checkOut: _d(11, 4),
        createdAt: _d(10, 15, 9, 15),
        paymentProof: AppImages.payment2,
      ),
      Reservation(
        id: 'r-dialga-0',
        cat: dialga,
        owner: najer,
        roomType: suite,
        checkIn: _d(9, 20),
        checkOut: _d(9, 22),
        createdAt: _d(9, 15),
        status: ReservationStatus.rejected,
        paymentProof: AppImages.payment3,
        adminNote:
            'Mohon maaf, tipe Suite penuh pada tanggal tersebut. '
            'Silakan pilih tanggal atau tipe lain.',
      ),
    ]);

    Reservation byId(String id) => reservations.firstWhere((r) => r.id == id);
    final dialgaStay = byId('r-dialga');
    final palkiaStay = byId('r-palkia');
    final giratinaStay = byId('r-giratina-2');
    DailyReport report(
      Reservation r,
      AppUser who,
      DateTime time,
      String food,
      String drink,
      String mood,
      String note,
    ) => DailyReport(
      reservation: r,
      reporter: who,
      time: time,
      food: food,
      drink: drink,
      mood: mood,
      note: note,
      photo: r.cat.photo,
    );
    reports.addAll([
      report(
        palkiaStay,
        mahar,
        _d(10, 13, 17, 30),
        'Sedikit',
        'Normal',
        'Kalem',
        'Masih adaptasi, banyak bersembunyi di cat tree.',
      ),
      report(
        palkiaStay,
        radit,
        _d(10, 14, 9, 5),
        'Habis',
        'Normal',
        'Kalem',
        'Sudah mulai nyaman, tidur di dekat jendela.',
      ),
      report(
        dialgaStay,
        mahar,
        _d(10, 14, 16, 20),
        'Sedikit',
        'Sedikit',
        'Kalem',
        'Hari pertama, makan separuh porsi.',
      ),
      report(
        palkiaStay,
        mahar,
        _d(10, 15, 17, 5),
        'Habis',
        'Normal',
        'Kalem',
        'Grooming lengkap selesai, bulu rapi.',
      ),
      report(
        dialgaStay,
        radit,
        _d(10, 15, 16, 50),
        'Habis',
        'Normal',
        'Aktif',
        'Main bola bulu hampir satu jam.',
      ),
      report(
        giratinaStay,
        mahar,
        _d(10, 15, 19, 10),
        'Sedikit',
        'Normal',
        'Kalem',
        'Baru tiba sore, sudah mau makan.',
      ),
      report(
        dialgaStay,
        mahar,
        _d(10, 16, 9, 12),
        'Habis',
        'Normal',
        'Aktif',
        'Makan lahap, aktif bermain.',
      ),
      report(
        palkiaStay,
        radit,
        _d(10, 16, 8, 40),
        'Habis',
        'Banyak',
        'Kalem',
        'Siap dijemput, kondisi sehat.',
      ),
    ]);

    blocks.addAll([
      UnitBlock(
        roomType: deluxe,
        unit: 'D3',
        start: _d(10, 15),
        end: _d(10, 18),
        reason: 'AC rusak',
      ),
      UnitBlock(
        roomType: standard,
        unit: 'S3',
        start: _d(10, 20),
        end: _d(10, 23),
        reason: 'AC rusak',
      ),
      UnitBlock(
        roomType: standard,
        unit: 'S4',
        start: _d(10, 28),
        end: _d(10, 30),
        reason: 'Cat ulang',
      ),
    ]);
  }
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
