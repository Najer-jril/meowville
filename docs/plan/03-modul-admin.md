# 03. Modul Admin

Use case dari diagram: membuat akun (include menetapkan hak akses akun), melihat akun user, menambah, mengedit, menghapus tipe kamar, melihat katalog tipe kamar, mengelola ketersediaan kamar, melihat daftar, menambah, menghapus, mengedit layanan addons, melihat laporan pethotel, mengonfirmasi reservasi. Admin juga bisa membuka mode sitter (`SitterShell(asAdmin: true)`), jadi admin mewarisi use case sitter.

Prasyarat: 01-database.md dan 05-flutter-core.md selesai.

| ID | Modul | Layar | Controller |
|---|---|---|---|
| A1 | Akun user dan hak akses | `user_list_screen`, `user_create_screen` | `UserController` |
| A2 | Tipe kamar | `room_screen`, `room_type_form_screen` | `RoomController` |
| A3 | Ketersediaan dan block unit | `room_screen`, `availability_calendar`, `block_unit_sheet` | `RoomController` |
| A4 | Layanan addon | `addon_list_screen`, `addon_form_screen` | `AddonController` |
| A5 | Laporan pet hotel | `report_screen` | `ReservationController` |
| A6 | Konfirmasi reservasi | `admin_dashboard_screen`, `reservation_list_screen`, `reservation_detail_screen`, `reservation_actions` | `ReservationController` |
| A7 | Lainnya dan mode sitter | `more_screen`, `admin_shell`, `sitter_shell` | gabungan |

---

## A1. Akun user dan hak akses

### Alur membuat akun

1. Admin isi nama, HP, email, password, pilih role (owner, sitter, admin).
2. `AuthService.signUp` membuat user. Trigger membuat profil dengan role `owner`.
3. Kalau role yang dipilih bukan owner, `ProfileService.setRole(id, role)` memanggil RPC `set_user_role`.
4. Reload daftar user.

Tidak perlu Edge Function atau service role key.

### Endpoint

| Aksi | Request |
|---|---|
| Daftar user | `GET /rest/v1/profiles?select=*&order=joined_at.desc` (admin membaca semua lewat RLS) |
| Buat akun | `POST /auth/v1/signup` body `{email, password, data: {name, phone}}` |
| Tetapkan role | `POST /rest/v1/rpc/set_user_role` body `{p_user, p_role}` |

### `UserController` (perluasan)

```dart
Future<void> create({
  required String name,
  required String phone,
  required String email,
  required String password,
  required UserRole role,
}) async {
  final id = await _auth.signUp(
    email: email,
    password: password,
    name: name,
    phone: phone,
  );
  if (role != UserRole.owner) {
    await _profiles.setRole(id, role);
  }
  await load();
}

void reset() {
  _users = [];
  notifyListeners();
}
```

Ubah `load()` memakai mixin `LoadState` (05 §5) supaya seragam.

Parameter `role` di `AuthService.signUp` dihapus, karena server mengabaikannya.

### Perubahan layar

| File | Ubah |
|---|---|
| `user_create_screen.dart` | Sudah memakai `UserController`. Tambah info di bawah tombol: "Akun staff perlu verifikasi email sebelum bisa login" (kalau Confirm email menyala). Tangani `ApiException` |
| `user_list_screen.dart` | Sudah memakai `UserController`. Tambah `RefreshIndicator` |

### Kasus khusus

| Kasus | Penanganan |
|---|---|
| Email sudah terdaftar dan Confirm email menyala | Supabase tidak mengembalikan error (mencegah enumerasi email), tapi mengembalikan user palsu. `emailTaken` di client mencegah kasus ini karena admin membaca semua profil |
| `signUp` sukses, `setRole` gagal (koneksi putus) | Akun tetap owner. Tampilkan pesan "Akun dibuat sebagai owner, role gagal diubah". Perbaiki manual di SQL Editor: `update profiles set role = 'sitter' where email = '...'` |
| Admin mengubah role akunnya sendiri | Ditolak RPC |
| Rate limit signup | Batas default Supabase cukup untuk admin. Kalau kena, pesan `rate limit` diterjemahkan (02 §O7a) |

### Selesai jika

- [ ] Admin membuat akun sitter, sitter login dan masuk ke `SitterShell`.
- [ ] Admin membuat akun admin kedua, akun itu masuk ke `AdminShell`.
- [ ] Daftar user menampilkan akun baru di urutan teratas.

---

## A2. Tipe kamar

"Menghapus tipe kamar" diwujudkan sebagai nonaktifkan, karena tipe kamar direferensikan reservasi lama. UI sekarang sudah memakai toggle aktif.

### Endpoint

| Aksi | Request |
|---|---|
| Daftar | `GET /rest/v1/room_types?select=*&order=price.asc` |
| Tambah | `POST /rest/v1/room_types` + `Prefer: return=representation` |
| Edit | `PATCH /rest/v1/room_types?id=eq.<id>` |
| Aktif/nonaktif | `PATCH /rest/v1/room_types?id=eq.<id>` body `{active}` |
| Upload foto | `POST /storage/v1/object/room-photos/<uid>/<ms>.jpg` |

### `lib/controllers/room_controller.dart`

```dart
class RoomController extends ChangeNotifier with LoadState {
  RoomController(this._service, this._storage);

  final RoomService _service;
  final StorageService _storage;

  String? _userId;
  List<RoomType> _types = [];
  List<UnitBlock> _blocks = [];
  final Map<String, DayAvailability> _availability = {};
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  List<RoomType> get types => _types;
  List<RoomType> get active => _types.where((t) => t.active).toList();
  List<UnitBlock> get blocks => _blocks;
  int get totalActiveUnits => active.fold(0, (sum, t) => sum + t.unitCount);

  Future<void> load({String? userId, bool withBlocks = false}) => runLoad(() async {
    _userId = userId ?? _userId;
    _types = await _service.fetchAll();
    if (withBlocks) _blocks = await _service.fetchBlocks(Clock.today());
  });

  bool prefixTaken(String prefix, {RoomType? except}) => _types.any(
    (t) => t != except && t.prefix.toUpperCase() == prefix.toUpperCase(),
  );

  Future<void> save(RoomType draft, {RoomType? existing}) async {
    final photo = isLocalPhoto(draft.photo)
        ? await _storage.upload(Buckets.rooms, _userId!, draft.photo!)
        : draft.photo;
    final type = draft.copyWith(photo: photo);
    if (existing == null) {
      await _service.create(type);
    } else {
      await _service.update(type);
    }
    await load();
    refreshAvailability();
  }

  Future<void> setActive(RoomType type, bool active) async {
    await _service.setActive(type.id, active);
    await load();
  }

  // A3: ketersediaan dan block, lihat di bawah

  void reset() {
    _userId = null;
    _types = [];
    _blocks = [];
    _availability.clear();
    _rangeStart = null;
    _rangeEnd = null;
    notifyListeners();
  }
}
```

`RoomType` butuh `copyWith` (tambahkan di `models.dart`). `loadSessionData` (05 §7) memanggil `rooms.load(userId: user.id, ...)` untuk admin.

### Perubahan layar

| File | Ubah |
|---|---|
| `room_type_form_screen.dart` | `_store.prefixTaken` menjadi `RoomController.prefixTaken`. `_store.saveRoomType(...)` menjadi `await RoomController.save(RoomType(id: widget.existing?.id ?? 0, ...), existing: widget.existing)`. Foto lewat `pickPhoto`. Field prefix disabled saat edit (server menolak perubahan prefix). Pola submit 05 §9 |
| `room_screen.dart` | `store.activeRoomTypes` dan daftar tipe menjadi `RoomController.types`/`active`. `store.setRoomTypeActive` menjadi `await RoomController.setActive` dalam `try`. `store.activeReservationCount(type)` menjadi `ReservationController.activeCountFor(type)` |

### Validasi

| Field | Client | Server |
|---|---|---|
| Nama | wajib | `not null` |
| Prefix | 1 sampai 3 huruf kapital, unik | `check (prefix ~ '^[A-Z]{1,3}$')`, `unique`, tidak bisa diubah (trigger) |
| Harga | angka ≥ 0 | `check (price >= 0)` |
| Jumlah unit | 1 sampai 99 | `check`, tidak bisa dikurangi kalau unit yang hilang dipakai reservasi aktif (trigger) |

Error unique prefix dari server diterjemahkan di `ApiClient` (05 §1).

### Selesai jika

- [ ] Tambah tipe kamar baru dengan foto, tampil di katalog owner.
- [ ] Edit harga. Reservasi lama tetap memakai harga lama (snapshot), reservasi baru memakai harga baru.
- [ ] Nonaktifkan tipe, tipe hilang dari katalog owner tapi reservasi lamanya tetap tampil normal.
- [ ] Kurangi jumlah unit saat unit terakhir sedang dipakai: ditolak.

---

## A3. Ketersediaan dan block unit

### Konsep

| Istilah | Arti | Sumber |
|---|---|---|
| occupied | reservasi `confirmed` atau `checked_in` di malam itu | RPC `room_availability` |
| pending | reservasi `pending` di malam itu (ikut mengurangi sisa supaya tidak overbooking) | RPC |
| blocked | unit diblokir admin (rusak, renovasi) | RPC |
| remaining | `units - occupied - pending - blocked`, minimal 0 | `DayAvailability.remaining` |

### Endpoint

| Aksi | Request |
|---|---|
| Ketersediaan semua tipe | `rpc/room_availability {p_type: null, p_start, p_end}` |
| Daftar block aktif | `GET /rest/v1/unit_blocks?select=*,room_type:room_types(*)&end_date=gte.<hari ini>&order=start_date` |
| Tambah block | `rpc/add_unit_block {p_type, p_unit, p_start, p_end, p_reason}` |
| Hapus block | `DELETE /rest/v1/unit_blocks?id=eq.<id>` |

### `RoomController` (lanjutan)

```dart
static String _key(int typeId, DateTime day) => '$typeId|${isoDate(day)}';

DayAvailability availability(RoomType type, DateTime day) =>
    _availability[_key(type.id, day)] ??
    DayAvailability(roomTypeId: type.id, day: day, units: type.unitCount,
        occupied: 0, pending: 0, blocked: 0);

/// Loads [start]..[end] inclusive and widens the remembered range so
/// [refreshAvailability] reloads everything on screen.
Future<void> loadAvailability(DateTime start, DateTime end) async {
  _rangeStart = _rangeStart == null || start.isBefore(_rangeStart!) ? start : _rangeStart;
  _rangeEnd = _rangeEnd == null || end.isAfter(_rangeEnd!) ? end : _rangeEnd;
  final days = await _service.availability(start: start, end: end);
  for (final d in days) {
    _availability[_key(d.roomTypeId, d.day)] = d;
  }
  notifyListeners();
}

Future<void> refreshAvailability() async {
  if (_rangeStart == null) return;
  await loadAvailability(_rangeStart!, _rangeEnd!);
}

Future<Map<int, int>> remainingBetween(DateTime start, DateTime endExclusive) async {
  // lihat 02-modul-owner.md §O3
}

List<UnitBlock> blocksFor(RoomType type) =>
    _blocks.where((b) => b.roomType == type).toList()
      ..sort((a, b) => a.start.compareTo(b.start));

/// Returns an error message, or null when the block was saved.
Future<String?> addBlock({
  required RoomType type,
  required String unit,
  required DateTime start,
  required DateTime end,
  required String reason,
}) async {
  try {
    await _service.addBlock(typeId: type.id, unit: unit, start: start, end: end, reason: reason);
  } on ApiException catch (e) {
    return e.message;
  }
  _blocks = await _service.fetchBlocks(Clock.today());
  await refreshAvailability();
  return null;
}

Future<void> removeBlock(UnitBlock block) async {
  await _service.removeBlock(block.id);
  _blocks = await _service.fetchBlocks(Clock.today());
  await refreshAvailability();
}
```

`addBlock` tetap mengembalikan `String?` seperti `AdminStore.addBlock`, jadi `block_unit_sheet` cukup ganti sumber. Pesan bentrok sekarang dibuat server (`Unit D3 punya reservasi pada 15/11 - 18/11. Batalkan reservasinya terlebih dahulu.`).

### Perubahan layar

| File | Ubah |
|---|---|
| `availability_calendar.dart` | `store.availability` menjadi `context.watch<RoomController>().availability`. `store.today` menjadi `Clock.today()`. Saat bulan berganti (`onMonthChanged`), panggil `RoomController.loadAvailability(awalBulan, akhirBulan)` dari parent (`room_screen`) |
| `block_unit_sheet.dart` | `_store.addBlock` menjadi `await RoomController.addBlock`, tombol simpan menampilkan loading. `_store.today` menjadi `Clock.today()` |
| `room_screen.dart` | `store.blocksFor` dan `store.removeBlock` dari `RoomController`. `initState`: `loadAvailability` untuk bulan yang tampil |
| `admin_dashboard_screen.dart` | `store.availability(t, store.today)` dan `store.blocks` dari `RoomController` |

### Selesai jika

- [ ] Kalender menampilkan sisa unit per hari sesuai data reservasi dan block.
- [ ] Block unit tanpa bentrok berhasil, sisa unit di kalender berkurang.
- [ ] Block unit yang bentrok dengan reservasi confirmed ditolak dengan pesan server.
- [ ] Hapus block, sisa unit kembali.
- [ ] Owner tidak bisa booking tipe yang semua unitnya diblokir di tanggal itu.

---

## A4. Layanan addon

"Menghapus layanan addon" diwujudkan sebagai nonaktifkan, sama seperti tipe kamar.

### Endpoint

| Aksi | Request |
|---|---|
| Daftar | `GET /rest/v1/addons?select=*&order=name` |
| Tambah | `POST /rest/v1/addons` + `Prefer: return=representation` |
| Edit | `PATCH /rest/v1/addons?id=eq.<id>` |
| Aktif/nonaktif | `PATCH /rest/v1/addons?id=eq.<id>` body `{active}` |

### `lib/controllers/addon_controller.dart`

```dart
class AddonController extends ChangeNotifier with LoadState {
  AddonController(this._service);

  final AddonService _service;
  List<Addon> _addons = [];

  List<Addon> get addons => _addons;
  List<Addon> get active => _addons.where((a) => a.active).toList();

  Future<void> load() => runLoad(() async {
    _addons = await _service.fetchAll();
  });

  Future<void> save(Addon draft, {Addon? existing}) async {
    if (existing == null) {
      await _service.create(draft);
    } else {
      await _service.update(draft);
    }
    await load();
  }

  Future<void> setActive(Addon addon, bool active) async {
    await _service.setActive(addon.id, active);
    await load();
  }

  void reset() {
    _addons = [];
    notifyListeners();
  }
}
```

### Perubahan layar

| File | Ubah |
|---|---|
| `addon_list_screen.dart` | `store.addons` dan `store.setAddonActive` dari `AddonController`. Loading, error, `RefreshIndicator` |
| `addon_form_screen.dart` | `AdminStore>().saveAddon(...)` menjadi `await AddonController.save(Addon(id: widget.existing?.id ?? 0, ...), existing: widget.existing)`. Pola submit 05 §9 |

### Selesai jika

- [ ] Tambah, edit, nonaktifkan addon. Owner hanya melihat addon aktif di step addon.
- [ ] Ubah harga addon tidak mengubah total reservasi lama.

---

## A5. Laporan pet hotel

Dihitung di client dari `ReservationController.all`, karena admin sudah memuat semua reservasi. Logika sama dengan `AdminStore.report`, tapi pendapatan memakai snapshot harga.

### `ReservationController.report`

```dart
ReportData report(DateTime start, DateTime end) {
  final rows = <RoomType, ReportRow>{};
  var nights = 0;
  final list = _all.where(
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
```

### Perubahan layar

`report_screen.dart`: `store.report(range.start, range.end)` menjadi `context.watch<ReservationController>().report(...)`. Tanggal acuan `_range` memakai `Clock.today()`. Tambah `RefreshIndicator` yang memanggil `ReservationController.load()`.

### Selesai jika

- [ ] Angka booking dan pendapatan bulan ini sama dengan hitungan manual dari SQL:
  ```sql
  select count(*), sum(room_price * (check_out - check_in)
    + coalesce((select sum(price) from reservation_addons ra where ra.reservation_id = r.id), 0))
  from reservations r
  where status in ('confirmed','checked_in','completed')
    and check_in between date_trunc('month', now())::date and now()::date;
  ```

---

## A6. Konfirmasi reservasi

### Alur

| Aksi | Syarat | RPC |
|---|---|---|
| Approve | status `pending`, pilih unit kosong | `approve_reservation {p_id, p_unit}` |
| Reject | status `pending`, alasan wajib | `reject_reservation {p_id, p_note}` |
| Batalkan | status `pending` atau `confirmed` | `cancel_reservation {p_id}` |

Daftar unit kosong untuk dropdown dihitung di client (`freeUnits`), server memvalidasi ulang saat approve.

### `lib/controllers/reservation_controller.dart`

Dipakai admin dan sitter.

```dart
class ReservationController extends ChangeNotifier with LoadState {
  ReservationController(this._service, this._rooms);

  final ReservationService _service;
  final RoomController _rooms;

  List<Reservation> _all = [];

  List<Reservation> get latest => _all; // server sudah urut created_at desc
  List<Reservation> get pending =>
      _all.where((r) => r.status == ReservationStatus.pending).toList();

  Future<void> load() => runLoad(() async {
    _all = await _service.fetchAll();
  });

  int activeCountFor(RoomType type) => _all
      .where((r) => r.roomType == type && r.status.isActive)
      .length;

  List<String> freeUnits(
    RoomType type,
    DateTime start,
    DateTime endExclusive, {
    Reservation? ignore,
  }) {
    // salin isi AdminStore.freeUnits (data.dart:82-115),
    // ganti `reservations` dengan `_all` dan `blocks` dengan `_rooms.blocks`
  }

  Future<void> approve(Reservation r, String unit) =>
      _mutate(() => _service.approve(r.id, unit));

  Future<void> reject(Reservation r, String note) =>
      _mutate(() => _service.reject(r.id, note));

  Future<void> cancel(Reservation r) =>
      _mutate(() => _service.cancel(r.id));

  Future<void> checkIn(Reservation r) =>
      _mutate(() => _service.checkIn(r.id));

  Future<void> checkOut(Reservation r) =>
      _mutate(() => _service.checkOut(r.id));

  Future<void> _mutate(Future<void> Function() action) async {
    await action();
    await load();
    _rooms.refreshAvailability();
  }

  // getter hari ini untuk sitter: lihat 04-modul-sitter.md §S1
  // report(): lihat §A5

  Reservation? byId(int id) =>
      _all.where((r) => r.id == id).firstOrNull;

  void reset() {
    _all = [];
    notifyListeners();
  }
}
```

### Perubahan layar

| File | Ubah |
|---|---|
| `admin_dashboard_screen.dart` | `store.pending` dari `ReservationController`. `_store.checkInsToday()`, `staying`, `checkOutsToday()` dari `ReservationController` (04 §S1). `totalActiveUnits`, `activeRoomTypes`, `availability` dari `RoomController`. `store.today`/`store.now` dari `Clock`. `RefreshIndicator` memanggil `ReservationController.load()` dan `RoomController.refreshAvailability()` |
| `reservation_list_screen.dart` | `_store.latest` dari `ReservationController.latest`. Filter dan pencarian tetap di client |
| `reservation_detail_screen.dart` | Ambil versi terbaru `ReservationController.byId(widget.reservation.id)`. `store.cancel(r)` (baris 112) menjadi `await ReservationController.cancel(r)` dalam `try` |
| `widgets/reservation_actions.dart` | `store.freeUnits` (baris 12) dari `ReservationController`. `approve` (baris 100) dan `reject` (baris 199) di-`await` dalam `try/on ApiException`, tombol menampilkan loading, sheet ditutup hanya kalau sukses |

### Kasus khusus

| Kasus | Penanganan |
|---|---|
| Dua admin approve reservasi berbeda dengan unit sama | RPC mengunci baris reservasi dan tipe, yang kedua mendapat "Unit ... sudah terisi" |
| Reservasi sudah diproses admin lain | RPC: "Reservasi sudah diproses". Reload daftar |
| Unit yang dipilih baru saja diblokir | RPC: "Unit ... sedang diblokir" |

### Selesai jika

- [ ] Approve dengan unit kosong, owner melihat status terkonfirmasi beserta unit.
- [ ] Dropdown unit tidak menampilkan unit yang terisi atau diblokir.
- [ ] Reject tanpa alasan ditolak, dengan alasan berhasil dan alasan tampil di owner.
- [ ] Batalkan reservasi confirmed, sisa unit di kalender bertambah.

---

## A7. Lainnya dan mode sitter

| File | Ubah |
|---|---|
| `more_screen.dart` | `AdminStore>().currentAdmin` menjadi `AuthController.user!`. Ringkasan `awaitingCheckIn`, `staying`, `dueCheckOut`, `reportToday` dari `ReservationController` dan `DailyReportController` |
| `sitter_shell.dart` | `_store.currentAdmin`/`_store.currentSitter` menjadi `context.read<AuthController>().user!` |
| `session_info_card.dart` | `confirmLogout` memanggil `resetSessionData(context)` sebelum `signOut` (05 §7) |

Admin tidak diberi tombol hapus akun, supaya tidak ada kemungkinan aplikasi kehilangan admin terakhir. Kebijakan Play hanya mewajibkan penghapusan untuk akun yang dibuat lewat aplikasi; akun admin dibuat manual.
