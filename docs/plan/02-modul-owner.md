# 02. Modul Pet Owner

Use case dari diagram: melihat, menambah, mengedit, menghapus profil hewan; melihat katalog tipe kamar; membuat reservasi (include memilih tipe kamar, extend menambah layanan tambahan); membatalkan reservasi; melihat laporan kondisi hewan; melihat riwayat booking; login; registrasi akun.

Prasyarat: 01-database.md selesai, 05-flutter-core.md §1 sampai §8 selesai.

| ID | Modul | Layar | Controller |
|---|---|---|---|
| O1 | Profil hewan | `pet_list_screen`, `pet_form_screen`, `pet_detail_screen` | `PetController` |
| O2 | Katalog tipe kamar | `room_catalog_screen`, `room_detail_screen` | `RoomController` |
| O3 | Membuat reservasi | `reservation/*` | `BookingController`, `RoomController`, `AddonController`, `PetController` |
| O4 | Riwayat dan detail booking | `booking_history_screen`, `booking_detail_screen`, `owner_widgets` | `BookingController` |
| O5 | Batal reservasi dan unggah bukti bayar | `booking_detail_screen` | `BookingController` |
| O6 | Laporan kondisi hewan | `pet_report_screen`, `owner_home_screen` | `DailyReportController` |
| O7 | Akun: registrasi, login, lupa password, profil, hapus akun | `auth/*`, `owner_account_screen`, `profile_form_screen` | `AuthController` |
| O8 | Beranda owner | `owner_home_screen`, `owner_shell` | gabungan |

---

## O1. Profil hewan

### Alur

- Lihat: `PetController.load(ownerId)` dipanggil saat login. `pet_list_screen` menampilkan `cats`.
- Tambah dan edit: form, pilih foto, simpan. Foto diupload ke bucket `cat-photos` lalu URL disimpan di `cats.photo`.
- Hapus: konfirmasi, lalu RPC `delete_cat` (soft delete). Server menolak kalau masih ada reservasi aktif.

### Endpoint

| Aksi | Request |
|---|---|
| Daftar | `GET /rest/v1/cats?select=*&owner_id=eq.<uid>&deleted=is.false&order=created_at.desc` |
| Tambah | `POST /rest/v1/cats` + `Prefer: return=representation`, body `{owner_id, name, breed, weight_kg, photo}` |
| Edit | `PATCH /rest/v1/cats?id=eq.<id>`, body `{name, breed, weight_kg, photo}` |
| Hapus | `POST /rest/v1/rpc/delete_cat` body `{p_id}` |
| Upload foto | `POST /storage/v1/object/cat-photos/<uid>/<ms>.jpg` |

### `lib/controllers/pet_controller.dart`

```dart
class PetController extends ChangeNotifier with LoadState {
  PetController(this._service, this._storage);

  final CatService _service;
  final StorageService _storage;

  String? _ownerId;
  List<Cat> _cats = [];

  List<Cat> get cats => _cats;

  Future<void> load([String? ownerId]) => runLoad(() async {
    _ownerId = ownerId ?? _ownerId;
    _cats = await _service.fetchMine(_ownerId!);
  });

  Future<Cat> save({
    Cat? existing,
    required String name,
    required String breed,
    required double weightKg,
    String? photo,
  }) async {
    final url = isLocalPhoto(photo)
        ? await _storage.upload(Buckets.cats, _ownerId!, photo!)
        : photo;
    final cat = existing == null
        ? await _service.create(_ownerId!, name: name, breed: breed, weightKg: weightKg, photo: url)
        : await _service.update(existing.id, name: name, breed: breed, weightKg: weightKg, photo: url);
    await load();
    return cat;
  }

  Future<void> delete(Cat cat) async {
    await _service.delete(cat.id);
    await load();
  }

  void reset() {
    _ownerId = null;
    _cats = [];
    notifyListeners();
  }
}
```

### Perubahan layar

| File | Ubah |
|---|---|
| `pet_list_screen.dart` | `store.catsOf(store.currentOwner)` menjadi `context.watch<PetController>().cats`. Tambah loading, error, `RefreshIndicator` (05 §9). `activeReservationOf` menjadi `context.watch<BookingController>().activeFor(cat)` |
| `pet_form_screen.dart` | Hapus `_store`. Tombol foto (baris 100) memanggil `pickPhoto(context)` dan menyimpan path ke `_photo`. Submit memakai pola 05 §9 dengan `PetController.save`. Tambah `_saving` |
| `pet_detail_screen.dart` | `store.activeReservationOf` menjadi `BookingController.activeFor`. `store.deleteCat` menjadi `await PetController.delete` dalam `try/on ApiException`. Pesan error server: "Kucing masih punya reservasi aktif" |

Karena `Cat` sekarang immutable, `pet_detail_screen` yang menerima `Cat` lewat argumen route harus mengambil versi terbaru setelah edit: `final cat = pets.cats.firstWhere((c) => c == widget.cat, orElse: () => widget.cat);`.

### Validasi

| Field | Client | Server |
|---|---|---|
| Nama | wajib | `check (length(trim(name)) > 0)` |
| Berat | angka > 0, koma diganti titik | `check (weight_kg > 0)`, `numeric(4,1)` maksimal 999,9 |
| Ras | opsional | default `''` |
| Foto | opsional | bucket maksimal 5 MB, jpeg/png/webp |

### Selesai jika

- [ ] Tambah kucing dengan foto kamera dan galeri, foto tampil setelah aplikasi ditutup dan dibuka lagi.
- [ ] Edit nama dan foto, perubahan terlihat di daftar dan detail.
- [ ] Hapus kucing tanpa reservasi aktif berhasil, kucing hilang dari daftar.
- [ ] Hapus kucing dengan reservasi pending ditolak dengan pesan dari server.
- [ ] Owner lain tidak melihat kucing ini (login akun owner kedua).

---

## O2. Katalog tipe kamar

### Alur

`RoomController.load()` dipanggil saat login. Owner hanya melihat `active`.

### Endpoint

`GET /rest/v1/room_types?select=*&order=price.asc`

### Perubahan layar

| File | Ubah |
|---|---|
| `room_catalog_screen.dart` | `store.activeRoomTypes` menjadi `context.watch<RoomController>().active`. Tambah loading dan `RefreshIndicator` |
| `room_detail_screen.dart` | `context.watch<AdminStore>()` (baris 20) dihapus. Ambil versi terbaru: `rooms.types.firstWhere((t) => t == widget.type, orElse: () => widget.type)` |

Foto kamar: seed memakai path asset, admin bisa mengganti dengan upload. `AppPhoto` sudah menangani keduanya (05 §4).

### Selesai jika

- [ ] Katalog hanya menampilkan tipe aktif.
- [ ] Admin menonaktifkan tipe, owner tarik untuk refresh, tipe hilang dari katalog.

---

## O3. Membuat reservasi

### Alur di layar `reservation_flow_screen`

| Step | Widget | Data |
|---|---|---|
| 0 | `StepPetDate` | Pilih kucing (`PetController.cats`), pilih rentang tanggal. Cek bentrok kucing dengan `BookingController.clashFor` |
| 1 | `StepRoom` | Daftar `RoomController.active` dengan sisa unit dari `BookingController.remaining` |
| 2 | `StepAddon` | `AddonController.active` (extend, boleh kosong) |
| 3 | `StepSummary` | Ringkasan, total, unggah bukti bayar (opsional, bisa nanti dalam 24 jam) |
| submit | | Upload bukti bayar kalau ada, lalu RPC `create_reservation` |

Sisa unit dihitung di server, karena owner tidak bisa membaca reservasi owner lain (RLS).

### Endpoint

| Aksi | Request |
|---|---|
| Sisa unit semua tipe | `POST /rest/v1/rpc/room_availability` body `{p_type: null, p_start: "2026-11-20", p_end: "2026-11-22"}` (p_end = check-out dikurangi 1 hari) |
| Upload bukti bayar | `POST /storage/v1/object/payment-proofs/<uid>/<ms>.jpg` |
| Buat reservasi | `POST /rest/v1/rpc/create_reservation` body `{p_cat, p_type, p_check_in, p_check_out, p_addons: [1,3], p_proof}`. Response: id reservasi baru |

### `lib/controllers/booking_controller.dart`

```dart
class BookingController extends ChangeNotifier with LoadState {
  BookingController(this._service, this._storage, this._rooms);

  final ReservationService _service;
  final StorageService _storage;
  final RoomController _rooms;

  String? _ownerId;
  List<Reservation> _reservations = [];
  Map<int, int> _remaining = {};
  bool _checkingRemaining = false;

  List<Reservation> get reservations => _reservations;
  Map<int, int> get remaining => _remaining;
  bool get checkingRemaining => _checkingRemaining;

  Future<void> load([String? ownerId]) => runLoad(() async {
    _ownerId = ownerId ?? _ownerId;
    _reservations = await _service.fetchMine(_ownerId!);
  });

  Reservation? activeFor(Cat cat) {
    final list = _reservations
        .where((r) => r.cat == cat && r.status.isActive)
        .toList()
      ..sort((a, b) => a.checkIn.compareTo(b.checkIn));
    return list.isEmpty ? null : list.first;
  }

  Reservation? clashFor(Cat cat, DateTime start, DateTime endExclusive) {
    for (final r in _reservations) {
      if (r.cat == cat &&
          r.status.isActive &&
          r.checkIn.isBefore(endExclusive) &&
          r.checkOut.isAfter(start)) {
        return r;
      }
    }
    return null;
  }

  DateTime proofDeadline(Reservation r) =>
      r.createdAt.add(const Duration(hours: 24));

  Future<void> loadRemaining(DateTime start, DateTime endExclusive) async {
    _checkingRemaining = true;
    notifyListeners();
    try {
      _remaining = await _rooms.remainingBetween(start, endExclusive);
    } finally {
      _checkingRemaining = false;
      notifyListeners();
    }
  }

  Future<Reservation> create({
    required Cat cat,
    required RoomType type,
    required DateTime checkIn,
    required DateTime checkOut,
    required Set<Addon> addons,
    String? proof,
  }) async {
    final proofPath = isLocalPhoto(proof)
        ? await _storage.upload(Buckets.proofs, _ownerId!, proof!)
        : proof;
    final id = await _service.create(
      catId: cat.id,
      typeId: type.id,
      checkIn: checkIn,
      checkOut: checkOut,
      addonIds: [for (final a in addons) a.id],
      proof: proofPath,
    );
    await load();
    _rooms.refreshAvailability();
    return _reservations.firstWhere((r) => r.id == id);
  }

  Future<void> uploadProof(Reservation r, String localPath) async {
    final path = await _storage.upload(Buckets.proofs, _ownerId!, localPath);
    await _service.uploadProof(r.id, path);
    await load();
  }

  Future<void> cancel(Reservation r) async {
    await _service.cancel(r.id);
    await load();
    _rooms.refreshAvailability();
  }

  void reset() {
    _ownerId = null;
    _reservations = [];
    _remaining = {};
    notifyListeners();
  }
}
```

`RoomController.remainingBetween` (detail di 03 §A3):

```dart
Future<Map<int, int>> remainingBetween(DateTime start, DateTime endExclusive) async {
  final days = await _service.availability(
    start: start,
    end: endExclusive.subtract(const Duration(days: 1)),
  );
  final result = <int, int>{};
  for (final d in days) {
    final left = d.remaining;
    result[d.roomTypeId] = math.min(result[d.roomTypeId] ?? left, left);
  }
  return result;
}
```

### Perubahan layar

| File | Ubah |
|---|---|
| `step_pet_date.dart` | `store.catsOf(store.currentOwner)` menjadi `PetController.cats`. `store.clashFor` menjadi `BookingController.clashFor`. `AdminStore>().today` menjadi `Clock.today()` |
| `reservation_flow_screen.dart` | `_next()` di step 0: `await context.read<BookingController>().loadRemaining(range.start, range.end)`, lalu kalau `remaining[_type!.id] ?? 0` < 1, `_type = null`. `_submit()`: panggil `loadRemaining` lagi untuk cek awal (dialog "Kamar baru saja penuh" tetap), lalu `await BookingController.create(...)` dalam `try/on ApiException`. Kalau pesan server "Kamar penuh di tanggal yang dipilih", tampilkan dialog yang sama dan kembali ke step 1. `_submitting` di-reset di `finally` |
| `step_room.dart` | `store.activeRoomTypes` menjadi `RoomController.active`. `store.remainingFor(t, ...)` menjadi `(booking.remaining[t.id] ?? 0)`. Saat `booking.checkingRemaining`, tampilkan indikator kecil |
| `step_addon.dart` | `AdminStore>().addons.where((a) => a.active)` menjadi `context.watch<AddonController>().active` |
| `step_summary.dart` | Tombol bukti bayar memanggil `pickPhoto`. Total memakai `type.price` (belum ada snapshot sebelum reservasi dibuat) |
| `reservation_success_screen.dart` | Tidak berubah, menerima `Reservation` hasil `create` |

### Kasus khusus

| Kasus | Penanganan |
|---|---|
| Dua owner booking unit terakhir bersamaan | RPC mengunci baris `room_types` (`for update`). Yang kedua mendapat "Kamar penuh di tanggal yang dipilih" |
| Admin menonaktifkan tipe saat owner di tengah alur | RPC: "Tipe kamar tidak tersedia". Kembali ke step 1 dan reload `RoomController` |
| Addon dinonaktifkan di tengah alur | RPC mengabaikan addon nonaktif (filter `a.active`). Total di reservasi mengikuti snapshot server |
| Upload bukti bayar sukses tapi RPC gagal | File yatim di bucket. Dibiarkan, ukurannya kecil |
| Check-in di masa lalu | RPC: "Tanggal check-in sudah lewat". Date picker juga dibatasi `firstDate: Clock.today()` |

### Selesai jika

- [ ] Reservasi baru muncul di riwayat owner dan di daftar pending admin.
- [ ] Total di ringkasan sama dengan total di detail booking dan detail admin.
- [ ] Tipe yang penuh di rentang tanggal tampil "penuh" dan tidak bisa dipilih.
- [ ] Booking untuk kucing yang sudah punya reservasi di tanggal bertumpuk ditolak.

---

## O4. Riwayat dan detail booking

### Perubahan layar

| File | Ubah |
|---|---|
| `booking_history_screen.dart` | `store.reservationsOf(store.currentOwner)` menjadi `BookingController.reservations` (sudah urut terbaru dari server). Loading, error, `RefreshIndicator` |
| `booking_detail_screen.dart` | Ambil versi terbaru dari `BookingController.reservations` berdasarkan id, karena status bisa berubah setelah reload |
| `owner_widgets.dart` | `store.now` menjadi `Clock.now()`, `store.proofDeadline` menjadi `BookingController.proofDeadline` |
| `payment_proof_card.dart` | Bukti bayar private: `FutureBuilder` dengan `StorageService.proofUrl(path)` (05 §4) |

`StorageService` perlu didaftarkan sebagai `Provider.value(value: storage)` di `main.dart` supaya `PaymentProofCard` bisa membacanya.

### Selesai jika

- [ ] Riwayat menampilkan semua status dengan label yang benar.
- [ ] Setelah admin approve, owner refresh dan melihat status terkonfirmasi beserta unit.
- [ ] Setelah admin reject, owner melihat alasan penolakan (`adminNote`).

---

## O5. Batal reservasi dan unggah bukti bayar

### Endpoint

| Aksi | Request | Syarat server |
|---|---|---|
| Batal | `rpc/cancel_reservation {p_id}` | Milik sendiri, status `pending` atau `confirmed` |
| Unggah bukti | Upload ke `payment-proofs`, lalu `rpc/upload_payment_proof {p_id, p_path}` | Milik sendiri, status `pending` |

### Perubahan layar

`booking_detail_screen.dart`:

- `_cancel` (baris 33): `store.cancel(reservation)` menjadi `await context.read<BookingController>().cancel(reservation)` dalam `try/on ApiException`.
- `store.uploadProof(r, path)` menjadi `pickPhoto` lalu `BookingController.uploadProof(r, path)`, dengan indikator loading di tombol.

### Selesai jika

- [ ] Batal reservasi pending dan confirmed berhasil, slot kamar kembali tersedia di step kamar.
- [ ] Tombol batal tidak muncul untuk status `checked_in`, `completed`, `rejected`, `cancelled`.
- [ ] Bukti bayar yang diunggah belakangan tampil di detail admin.

---

## O6. Laporan kondisi hewan

### Endpoint

`GET /rest/v1/daily_reports?select=*,reporter:profiles(*),reservation:reservations(...)&order=time.desc`

RLS membatasi owner hanya ke laporan reservasi miliknya, jadi `DailyReportController.load()` bisa dipakai bersama sitter. Detail controller di 04 §S2.

### Perubahan layar

| File | Ubah |
|---|---|
| `pet_report_screen.dart` | `store.reportHistory` menjadi `DailyReportController.forReservation(reservation)`. `d.reporter.firstName` (baris 145) menjadi `d.reporter?.firstName ?? 'staff'`. Tambah `RefreshIndicator` yang memanggil `DailyReportController.load()` |
| `owner_home_screen.dart` | `store.reportToday(r)` menjadi `DailyReportController.reportToday(r)` |

### Selesai jika

- [ ] Sitter mengirim laporan, owner refresh dan melihatnya beserta foto.
- [ ] Owner lain tidak melihat laporan ini.

---

## O7. Akun

### O7a. Registrasi

Sudah berjalan lewat `AuthService.signUp`. Perubahan:

- Role di metadata diabaikan server (selalu owner). Hapus `role: UserRole.owner` dari pemanggilan di `registration_screen.dart:74`, atau biarkan; tidak ada efek.
- Kalau "Confirm email" menyala, ganti pesan sukses menjadi "Akun dibuat. Cek email untuk verifikasi sebelum login."
- Terjemahkan pesan error di `login_screen.dart` `_loginError`:

| Pesan server | Tampilkan |
|---|---|
| `Invalid login credentials` | (sudah ada) |
| `Email not confirmed` | `Email belum diverifikasi. Cek kotak masuk atau folder spam.` |
| `User already registered` | `Email sudah terdaftar` |
| mengandung `rate limit` | `Terlalu banyak percobaan. Coba lagi beberapa menit lagi.` |

### O7b. Lupa password (OTP)

`forgot_password_screen.dart` sekarang hanya simulasi (`_send` tidak memanggil API). Ubah menjadi dua tahap:

| Tahap | UI | Aksi |
|---|---|---|
| 1 | Field email, tombol "Kirim kode" | `AuthController.sendResetCode(email)`, lalu countdown kirim ulang (sudah ada) |
| 2 | Field kode 6 digit, password baru, konfirmasi password | `AuthController.resetPassword(email, code, password)`, lalu snack "Password diperbarui" dan ke login |

```dart
Future<void> sendResetCode(String email) => _auth.recover(email);

Future<void> resetPassword(String email, String code, String password) async {
  final temp = await _auth.verifyRecovery(email, code);
  _api.accessToken = temp.accessToken;
  try {
    await _auth.updatePassword(password);
    await _auth.signOut();
  } finally {
    _api.accessToken = _session?.accessToken;
  }
}
```

Error kode salah atau kedaluwarsa dari server: `Token has expired or is invalid`. Terjemahkan menjadi "Kode salah atau sudah kedaluwarsa".

### O7c. Edit profil

`profile_form_screen.dart`: `AdminStore>().updateProfile` menjadi:

```dart
Future<void> updateProfile({required String name, required String phone, String? photo}) async {
  final url = isLocalPhoto(photo)
      ? await _storage.upload(Buckets.avatars, _user!.id, photo!)
      : photo;
  _user = await _profiles.update(_user!.id, name: name, phone: phone, photo: url);
  notifyListeners();
}
```

di `AuthController`. Semua layar yang memakai `AuthController.user` otomatis ikut terbarui.

### O7d. Hapus akun (wajib Play Store)

`owner_account_screen.dart` (dan `sitter/account_screen.dart`): tambah item "Hapus akun" berwarna danger di atas "Keluar".

Alur:

1. Dialog konfirmasi: "Akun, data kucing, dan riwayat reservasi akan dihapus permanen. Tindakan ini tidak bisa dibatalkan." Tombol "Hapus akun" (danger) dan "Batal".
2. Layar mengecek dulu `context.read<BookingController>().reservations.any((r) => r.status.isActive)`. Kalau ada, tampilkan "Masih ada reservasi aktif. Batalkan atau selesaikan dulu." dan berhenti. Pengecekan ini mencegah foto terhapus padahal RPC akan menolak.
3. `AuthController.deleteAccount()`:
   ```dart
   Future<void> deleteAccount() async {
     try {
       await _storage.deleteOwnFiles(_user!.id);
     } on Object {
       // file yatim tidak menghalangi penghapusan akun
     }
     await _profiles.deleteMe();
     await _clear();
   }
   ```
   File dihapus sebelum RPC, karena setelah user dihapus token-nya tidak bisa dipakai lagi untuk Storage API. Server tetap mengecek reservasi aktif sebagai pengaman terakhir.
4. `resetSessionData`, lalu ke layar login dengan snack "Akun berhasil dihapus".

Error "Masih ada reservasi aktif" ditampilkan apa adanya.

### O7e. Halaman legal

`policy_screen.dart` dan `legal_screen.dart` sudah ada. Pastikan isinya sama dengan halaman privacy policy di web (06 §6), dan tambahkan tautan ke halaman itu dari layar akun.

### Selesai jika

- [ ] Registrasi akun baru, verifikasi email, login berhasil.
- [ ] Lupa password: kode sampai di email, password baru bisa dipakai login.
- [ ] Edit nama dan nomor HP tersimpan setelah aplikasi dibuka ulang.
- [ ] Hapus akun tanpa reservasi aktif berhasil dan email yang sama bisa daftar lagi.
- [ ] Hapus akun dengan reservasi aktif ditolak.

---

## O8. Beranda owner

`owner_home_screen.dart`: ganti `store.currentOwner` dengan `AuthController.user`, `store.reservationsOf` dengan `BookingController.reservations`, `store.today` dengan `Clock.today()`, `store.reportToday` dengan `DailyReportController.reportToday`. `RefreshIndicator` memanggil `BookingController.load()` dan `DailyReportController.load()` bersamaan dengan `Future.wait`.

`owner_account_screen.dart:20`: `context.watch<AuthController>().user ?? store.currentOwner` menjadi `context.watch<AuthController>().user!`.
