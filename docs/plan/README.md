# Plan Implementasi Backend Meowville

Rencana kerja dari kondisi sekarang (UI lengkap, data masih dummy di `AdminStore`) sampai aplikasi siap diunggah ke Google Play. Dokumen ini dipakai sebagai pegangan harian: buka file ini, lanjutkan dari checklist yang belum dicentang.

- Tanggal plan: 15 November 2026, commit `8533bcf`
- Target unggah: Rabu, 18 November 2026
- Stack: Flutter 3.47 + Supabase (Auth, PostgREST, Storage), tanpa SDK `supabase_flutter`. Semua akses lewat `ApiClient` (HTTP) seperti pola login, register, dan profile yang sudah ada.

## Daftar dokumen

| File | Isi |
|---|---|
| [01-database.md](01-database.md) | Skema, RLS, RPC, Storage, setting Auth Supabase. Berisi SQL lengkap siap jalan. |
| [02-modul-owner.md](02-modul-owner.md) | Modul pet owner: profil hewan, katalog, reservasi, riwayat, laporan, akun. |
| [03-modul-admin.md](03-modul-admin.md) | Modul admin: akun, tipe kamar, ketersediaan, addon, konfirmasi reservasi, laporan. |
| [04-modul-sitter.md](04-modul-sitter.md) | Modul pet sitter (staff): check-in/out dan laporan harian. |
| [05-flutter-core.md](05-flutter-core.md) | Perubahan inti Flutter: `ApiClient`, model, service, controller, foto, migrasi dari `AdminStore`. |
| [06-android-playstore.md](06-android-playstore.md) | Manifest, permission, signing, build, dan seluruh isian Play Console. |

## Temuan yang wajib dibereskan

| # | Masalah | Lokasi | Dampak | Diselesaikan di |
|---|---|---|---|---|
| B1 | Permission `INTERNET` tidak ada di manifest `main` | `android/app/src/main/AndroidManifest.xml` | Build release tidak bisa memanggil Supabase sama sekali | 06 |
| B2 | Role diambil dari `raw_user_meta_data` saat signup | `supabase/schema.sql` fungsi `create_profile` | Siapa pun bisa daftar sebagai admin lewat `/auth/v1/signup` | 01 |
| B3 | Policy RLS "dev full access" | `supabase/schema.sql` | Semua user login bisa baca, ubah, hapus semua data, termasuk mengubah role sendiri | 01 |
| B4 | `schema.sql` berisi `drop table` dan `delete from auth.users` | `supabase/schema.sql` | Sekali dijalankan di produksi, semua data hilang | 01 |
| B5 | Release ditandatangani debug key | `android/app/build.gradle.kts` | Play Console menolak AAB | 06 |
| B6 | Upload foto masih palsu (selalu `AppImages.catDialga`) | `pet_form_screen.dart:100`, form laporan, bukti bayar | Fitur foto tidak berfungsi | 05 |
| B7 | Tanggal "hari ini" di-hardcode `DateTime(2026, 10, 16)` | `lib/data/data.dart:12`, dipakai 26 tempat | Jadwal check-in/out, kalender, dan laporan salah | 05 |
| B8 | Email bawaan Supabase hanya mengirim ke alamat anggota tim dan dibatasi beberapa email per jam | Supabase Auth | Konfirmasi email dan reset password tidak sampai ke user asli | 01 |
| B9 | Tidak ada fitur hapus akun | - | Wajib oleh kebijakan Play untuk app yang punya registrasi | 01, 02, 06 |
| B10 | Akun developer personal yang dibuat setelah 13 Nov 2023 wajib closed testing 12 tester selama 14 hari sebelum boleh rilis Production | Play Console | Target 3 hari realistisnya: submit ke closed testing | 06 |

## Arsitektur yang dipakai

```
lib/core/api_client.dart          HTTP ke Supabase (+ rpc, upload, put, retry 401)
lib/services/<domain>_service.dart   satu file per domain, return model
lib/controllers/<domain>_controller.dart   ChangeNotifier: state, loading, error
lib/screens/...                    context.watch<XController>() menggantikan AdminStore
```

Aturan:

1. Validasi yang bisa bentrok antar user (sisa kamar, unit kosong, block unit, transisi status) dijalankan di Postgres lewat RPC `security definer`. Client boleh menghitung untuk tampilan, tapi server yang menentukan.
2. Hak akses ditegakkan RLS. Pengecekan role di UI hanya untuk tampilan.
3. Service dibagi per domain, bukan per role, supaya tidak ada query ganda. Pembagian per role ada di dokumen 02, 03, 04.
4. Setiap mutasi: panggil service, lalu muat ulang data yang terdampak, lalu `notifyListeners()`. Tidak ada realtime; layar daftar memakai pull-to-refresh.

## Lingkungan Supabase

Pakai dua project (free tier mengizinkan dua):

| Project | Isi | Dipakai oleh |
|---|---|---|
| `meowville-dev` (project yang sekarang) | Skema + data dummy dari `supabase/dev/` | `flutter run` saat development |
| `meowville-prod` (baru) | Skema + master data (tipe kamar, addon) + akun admin asli | Build release yang diunggah ke Play |

`.env` saat build release harus berisi URL dan publishable key project prod. Jangan pernah memasukkan `service_role` key ke `.env`, karena file ini ikut terbungkus di APK.

## Jadwal dan checklist

Centang (`[x]`) setiap selesai. Kolom "Selesai jika" adalah syarat verifikasi, bukan sekadar "kode sudah ditulis".

### Hari 1: Minggu, 15 November (database dan fondasi)

Pagi: database

- [ ] D1-01 Buat folder `supabase/migrations/` dan `supabase/dev/`. Pindahkan isi drop + seed user dari `schema.sql` ke `supabase/dev/reset.sql` dan `supabase/dev/seed_users.sql`. Hapus `supabase/schema.sql`. Selesai jika tidak ada lagi `drop` atau `delete from auth.users` di `migrations/`.
- [ ] D1-02 Tulis `001_schema.sql` (01-database.md §2). Selesai jika berhasil dijalankan di project dev yang sudah di-reset.
- [ ] D1-03 Tulis `002_rls.sql` (§3). Selesai jika uji curl §8 lolos: owner gagal mengubah role sendiri, owner tidak bisa membaca kucing user lain.
- [ ] D1-04 Tulis `003_rpc.sql` (§4). Selesai jika `create_reservation` menolak saat kamar penuh dan `approve_reservation` menolak unit yang sudah terpakai.
- [ ] D1-05 Tulis `004_storage.sql` (§5). Selesai jika upload lewat curl ke `cat-photos/<uid>/x.jpg` berhasil dan ke folder user lain ditolak.
- [ ] D1-06 Tulis `005_master_data.sql` (tipe kamar dan addon). Jalankan seed user dev.

Siang: fondasi Flutter (05-flutter-core.md)

- [ ] D1-07 `ApiClient`: tambah `rpc`, `put`, `upload`, `publicUrl`, `signedUrl`, header `Prefer`, retry sekali saat 401. (§1)
- [ ] D1-08 `lib/utils/clock.dart` untuk tanggal hari ini. (§6)
- [ ] D1-09 `models.dart`: `id`, `fromJson`, `toJson`, `==`/`hashCode` berbasis id, snapshot harga di `Reservation`. Pindahkan `ReportRow` dan `ReportData` ke `models.dart`. (§2)
- [ ] D1-10 Tambah `image_picker` ke `pubspec.yaml`, buat `StorageService` dan `PhotoPicker`. Ubah `AppPhoto` agar bisa menampilkan URL. (§4)

Sore: service dan controller

- [ ] D1-11 Service: `cat`, `room`, `addon`, `reservation`, `daily_report`, perluasan `profile` dan `auth`. (§3)
- [ ] D1-12 Controller: `PetController`, `BookingController`, `RoomController`, `AddonController`, `ReservationController`, `DailyReportController`, perluasan `AuthController` dan `UserController`. Daftarkan di `main.dart`. (§5)
- [ ] D1-13 Login sebagai owner, admin, dan sitter di emulator. Selesai jika ketiganya masuk ke home masing-masing tanpa error (screen masih boleh memakai `AdminStore`).

Paralel hari 1 (tidak butuh kode, kerjakan saat menunggu build atau di sela-sela):

- [ ] D1-P1 Pastikan akun Play Console aktif dan verifikasi identitas selesai. Proses ini bisa makan beberapa hari, jadi cek sekarang. Cek juga apakah akun personal atau organisasi (menentukan B10).
- [ ] D1-P2 Buat project `meowville-prod` di Supabase.
- [ ] D1-P3 Daftar SMTP gratis (Resend atau Brevo) dan pasang di kedua project (01-database.md §6).
- [ ] D1-P4 Siapkan aset store: ikon 512×512, feature graphic 1024×500 (06 §8).

### Hari 2: Senin, 16 November (sambungkan semua layar)

- [ ] D2-01 Auth dan akun: `enterHome` memuat data per role, logout mereset semua controller, forgot password OTP, edit profil, hapus akun. (02 §O7, 05 §7)
- [ ] D2-02 Owner: profil hewan (O1). Selesai jika tambah, edit (dengan foto asli), hapus berjalan dan hapus ditolak saat ada reservasi aktif.
- [ ] D2-03 Owner: katalog kamar (O2) dan alur reservasi (O3). Selesai jika reservasi baru muncul di daftar admin.
- [ ] D2-04 Owner: riwayat, detail, unggah bukti bayar, batal (O4, O5).
- [ ] D2-05 Admin: dashboard dan daftar reservasi, approve, reject, cancel (A6).
- [ ] D2-06 Admin: tipe kamar, block unit, kalender ketersediaan (A2, A3).
- [ ] D2-07 Admin: addon (A4), akun user (A1), laporan (A5).
- [ ] D2-08 Sitter: today, check-in, check-out (S1).
- [ ] D2-09 Sitter: form laporan harian dengan foto dan riwayat laporan (S2). Owner melihat laporan (O6).
- [ ] D2-10 Hapus `lib/data/data.dart` dan `AdminStore` dari `main.dart` serta `app_routes.dart`. Selesai jika `flutter analyze` bersih.
- [ ] D2-11 Uji skenario end-to-end (06 §10) di HP fisik.

### Hari 3: Selasa, 17 November (release)

- [ ] D3-01 Manifest final, label "Meowville", ikon (06 §1, §2).
- [ ] D3-02 Keystore, `key.properties`, signing release (06 §3).
- [ ] D3-03 Jalankan migration 001 sampai 005 di `meowville-prod`. Buat akun admin asli dan tiga akun demo untuk reviewer (01 §7).
- [ ] D3-04 Halaman privacy policy dan halaman hapus akun di GitHub Pages (06 §6).
- [ ] D3-05 `.env` diarahkan ke prod, naikkan versi, `flutter build appbundle` (06 §4).
- [ ] D3-06 Uji AAB release di HP lewat internal testing (06 §9).
- [ ] D3-07 Isi semua bagian Play Console (06 §7, §8).
- [ ] D3-08 Kirim ke closed testing (akun personal) atau Production (akun organisasi).

### Rabu, 18 November: cadangan

Dipakai untuk perbaikan dari internal testing atau penolakan review.

## Yang boleh dipotong kalau waktu mepet

Urutan dari yang paling aman dipotong:

1. Retry otomatis saat 401 (timer refresh di `AuthController` sudah ada).
2. Signed URL bukti bayar. Sementara bucket `payment-proofs` dibuat public dengan nama file acak.
3. Trigger penjaga perubahan jumlah unit tipe kamar.
4. Auto-batal reservasi yang tidak mengunggah bukti bayar dalam 24 jam (memang belum ada di plan inti).

Yang tidak boleh dipotong: B1 sampai B5, B8, B9, RLS, dan RPC reservasi.

## Cara melanjutkan di hari berikutnya

1. Buka file ini, cari checklist pertama yang belum dicentang.
2. Buka dokumen yang dirujuk dan kerjakan bagian yang disebut.
3. Commit per checklist dengan pesan yang menyebut ID, misalnya `feat(owner): pet CRUD via Supabase (D2-02)`.
