# 04. Modul Pet Sitter (Staff)

Use case dari diagram: login, mengelola status in dan out hewan, melaporkan kondisi hewan harian. Admin juga memakai layar-layar ini lewat `SitterShell(asAdmin: true)`, jadi semua RPC dan RLS di modul ini mengizinkan role `sitter` dan `admin`.

Prasyarat: 01-database.md, 05-flutter-core.md, dan `ReservationController` dari 03 §A6 sudah ada.

| ID | Modul | Layar | Controller |
|---|---|---|---|
| S1 | Status check-in dan check-out | `today_screen`, `booking_detail_screen` | `ReservationController` |
| S2 | Laporan kondisi harian | `daily_report_form_screen`, `report_history_screen` | `DailyReportController` |
| S3 | Akun sitter | `account_screen`, `sitter_shell` | `AuthController`, gabungan |

---

## S1. Status check-in dan check-out

### Transisi status

```
pending ──approve──> confirmed ──check_in──> checked_in ──check_out──> completed
   │                     │
   └──reject──> rejected └──cancel──> cancelled
   └──cancel──> cancelled
```

| Aksi | Syarat server | RPC |
|---|---|---|
| Check-in | status `confirmed` dan `check_in <= hari ini (WIB)` | `check_in_reservation {p_id}` |
| Check-out | status `checked_in` | `check_out_reservation {p_id}` |

Check-out lebih awal dari tanggal `check_out` diizinkan (owner menjemput lebih cepat). Check-in lebih awal dari tanggal `check_in` ditolak, karena unitnya belum tentu kosong.

### `ReservationController` (getter hari ini)

Disalin dari `AdminStore` (data.dart:117-162), dengan `today` diganti `Clock.today()` dan `reservations` diganti `_all`:

```dart
static bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

List<Reservation> checkInsToday() {
  final today = Clock.today();
  return _all
      .where((r) => _sameDay(r.checkIn, today) && r.status.holdsUnit)
      .toList();
}

List<Reservation> checkOutsToday() {
  final today = Clock.today();
  return _all
      .where(
        (r) =>
            _sameDay(r.checkOut, today) &&
            (r.status == ReservationStatus.checkedIn ||
                r.status == ReservationStatus.completed),
      )
      .toList();
}

List<Reservation> get staying =>
    _all.where((r) => r.status == ReservationStatus.checkedIn).toList();

List<Reservation> get awaitingCheckIn {
  final today = Clock.today();
  return _all
      .where(
        (r) =>
            r.status == ReservationStatus.confirmed &&
            !r.checkIn.isAfter(today),
      )
      .toList()
    ..sort((a, b) => a.checkIn.compareTo(b.checkIn));
}

List<Reservation> get stayingNotLeaving {
  final today = Clock.today();
  return staying.where((r) => r.checkOut.isAfter(today)).toList()
    ..sort((a, b) => a.checkOut.compareTo(b.checkOut));
}

List<Reservation> get dueCheckOut {
  final today = Clock.today();
  return staying.where((r) => !r.checkOut.isAfter(today)).toList();
}
```

`checkIn` dan `checkOut` sudah ada di 03 §A6 lewat `_mutate`.

### Perubahan layar

| File | Ubah |
|---|---|
| `today_screen.dart` | `store.awaitingCheckIn`, `stayingNotLeaving`, `dueCheckOut` dari `ReservationController`. `store.today` menjadi `Clock.today()`. `AdminStore>().reportToday` menjadi `DailyReportController.reportToday`. `report.reporter` menjadi `report.reporter?.firstName ?? 'staff'`. `RefreshIndicator` memanggil `ReservationController.load()` dan `DailyReportController.load()` |
| `booking_detail_screen.dart` | Ambil versi terbaru dengan `ReservationController.byId(widget.reservation.id)`. `_checkIn` (baris 46): `context.read<AdminStore>().checkIn(r)` menjadi `await context.read<ReservationController>().checkIn(r)` dalam `try/on ApiException`. `_checkOut` (baris 53, 79): `reportToday` dari `DailyReportController`, `checkOut` dari `ReservationController`. Dialog peringatan "Belum ada laporan hari ini" tetap |

### Selesai jika

- [ ] Reservasi confirmed dengan check-in hari ini muncul di "menunggu check-in".
- [ ] Check-in berhasil, reservasi pindah ke "sedang menginap", owner melihat status berubah.
- [ ] Check-in untuk reservasi dengan tanggal besok ditolak server.
- [ ] Check-out berhasil, unit kembali tersedia di kalender admin untuk malam berikutnya.
- [ ] Admin dalam mode sitter bisa melakukan semua aksi di atas.

---

## S2. Laporan kondisi harian

### Alur

1. Sitter membuka reservasi yang sedang `checked_in`, tekan "Buat laporan".
2. Isi makan, minum, mood (wajib), catatan dan foto (opsional).
3. Foto diupload ke `report-photos/<uid>/<ms>.jpg`, lalu baris `daily_reports` di-insert.
4. Owner melihat laporan di `pet_report_screen` (02 §O6).

### Endpoint

| Aksi | Request |
|---|---|
| Daftar | `GET /rest/v1/daily_reports?select=*,reporter:profiles(*),reservation:reservations(<Reservation.select>)&order=time.desc` |
| Tambah | `POST /rest/v1/daily_reports` + `Prefer: return=representation`, body `{reservation_id, reporter_id, food, drink, mood, note, photo}` |
| Upload foto | `POST /storage/v1/object/report-photos/<uid>/<ms>.jpg` |

Kolom `time` diisi server (`default now()`), jadi jam laporan tidak bergantung jam HP.

RLS insert mewajibkan `reporter_id = auth.uid()`, role sitter atau admin, dan reservasi berstatus `checked_in`.

### `lib/controllers/daily_report_controller.dart`

```dart
class DailyReportController extends ChangeNotifier with LoadState {
  DailyReportController(this._service, this._storage);

  final DailyReportService _service;
  final StorageService _storage;

  List<DailyReport> _reports = [];

  /// Newest first.
  List<DailyReport> get history => _reports;

  Future<void> load() => runLoad(() async {
    _reports = await _service.fetchAll();
  });

  List<DailyReport> forReservation(Reservation r) =>
      _reports.where((d) => d.reservation == r).toList();

  DailyReport? reportToday(Reservation r) {
    final today = Clock.today();
    return _reports
        .where(
          (d) =>
              d.reservation == r &&
              d.time.year == today.year &&
              d.time.month == today.month &&
              d.time.day == today.day,
        )
        .firstOrNull;
  }

  int countToday(AppUser reporter) {
    final today = Clock.today();
    return _reports
        .where(
          (d) =>
              d.reporter == reporter &&
              d.time.year == today.year &&
              d.time.month == today.month &&
              d.time.day == today.day,
        )
        .length;
  }

  Future<void> add({
    required Reservation reservation,
    required AppUser reporter,
    required String food,
    required String drink,
    required String mood,
    String note = '',
    String? photo,
  }) async {
    final url = isLocalPhoto(photo)
        ? await _storage.upload(Buckets.reports, reporter.id, photo!)
        : photo;
    await _service.create(
      reservationId: reservation.id,
      reporterId: reporter.id,
      food: food,
      drink: drink,
      mood: mood,
      note: note,
      photo: url,
    );
    await load();
  }

  void reset() {
    _reports = [];
    notifyListeners();
  }
}
```

`d.reporter == reporter` membutuhkan `==` berbasis id di `AppUser`. Tambahkan seperti model lain (05 §2).

### Perubahan layar

| File | Ubah |
|---|---|
| `daily_report_form_screen.dart` | `_submit` jadi `async`. `_store.addReport(...)` menjadi `await DailyReportController.add(...)` dengan `_saving` dan `try/on ApiException`. `Navigator.pop` dan snack hanya setelah sukses. `_store.reportToday(r)` (baris 68) dari `DailyReportController`. `_store.now` (baris 127) menjadi `Clock.now()`. Tombol foto memanggil `pickPhoto` |
| `report_history_screen.dart` | `store.reportHistory` (baris 27) menjadi `DailyReportController.history`. `store.today` (baris 58) menjadi `Clock.today()`. `RefreshIndicator` |

### Kasus khusus

| Kasus | Penanganan |
|---|---|
| Kucing sudah check-out saat sitter menekan kirim | RLS menolak insert. Pesan dari PostgREST: `new row violates row-level security policy`. Terjemahkan di `ApiClient` menjadi "Laporan hanya bisa dibuat untuk kucing yang sedang menginap" |
| Upload foto gagal (sinyal lemah) | Error tampil, form tidak tertutup, isian tidak hilang. Sitter bisa coba lagi |
| Lebih dari satu laporan sehari | Diizinkan. `reportToday` menampilkan yang terbaru |

### Selesai jika

- [ ] Kirim laporan dengan foto, laporan tampil di riwayat sitter dan di aplikasi owner.
- [ ] Field wajib kosong tetap memunculkan error merah (perilaku lama).
- [ ] Mencoba membuat laporan untuk reservasi yang sudah check-out ditolak.

---

## S3. Akun sitter

| File | Ubah |
|---|---|
| `sitter_shell.dart` | `_store.currentAdmin`/`_store.currentSitter` (baris 23-25) menjadi `context.read<AuthController>().user!` |
| `account_screen.dart` | `store.staying.length` dari `ReservationController`. Hitungan laporan hari ini (baris 24-30) menjadi `DailyReportController.countToday(user)`. Tambah item "Edit profil" (memakai `profile_form_screen` yang sama dengan owner) dan "Hapus akun" (02 §O7d, tanpa pengecekan reservasi) |

### Selesai jika

- [ ] Akun sitter menampilkan nama dari database, jumlah kucing menginap, dan jumlah laporan hari ini yang benar.
- [ ] Logout lalu login sebagai owner tidak menampilkan data sitter.
