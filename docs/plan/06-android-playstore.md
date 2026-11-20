# 06. Android dan Google Play

Semua yang dibutuhkan dari kode Android sampai aplikasi terkirim untuk review.

## 1. `android/app/src/main/AndroidManifest.xml`

Versi final:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET"/>

    <application
        android:label="Meowville"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:allowBackup="false"
        android:dataExtractionRules="@xml/data_extraction_rules">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>

    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
```

File baru `android/app/src/main/res/xml/data_extraction_rules.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
    <cloud-backup>
        <exclude domain="sharedpref" path="."/>
    </cloud-backup>
    <device-transfer>
        <exclude domain="sharedpref" path="."/>
    </device-transfer>
</data-extraction-rules>
```

### Alasan setiap baris

| Baris | Alasan |
|---|---|
| `INTERNET` | Wajib untuk memanggil Supabase. Sekarang hanya ada di manifest `debug` dan `profile`, jadi build release gagal konek (B1) |
| `android:label="Meowville"` | Nama di launcher. Sekarang huruf kecil |
| `allowBackup="false"` | Android 11 ke bawah: token sesi di SharedPreferences tidak ikut backup Google Drive |
| `dataExtractionRules` | Android 12 ke atas: `allowBackup` tidak lagi menghentikan transfer antar perangkat, jadi SharedPreferences dikecualikan secara eksplisit |

### Permission yang sengaja tidak ditambahkan

| Permission | Kenapa tidak |
|---|---|
| `CAMERA` | `image_picker` membuka aplikasi kamera sistem lewat intent. Kalau `CAMERA` dideklarasikan tapi tidak diminta saat runtime, intent kamera justru gagal dengan `SecurityException` |
| `READ_MEDIA_IMAGES`, `READ_EXTERNAL_STORAGE` | `image_picker` memakai Photo Picker sistem. Play membatasi `READ_MEDIA_IMAGES` untuk aplikasi yang aksesnya ke galeri adalah fungsi inti, dan meminta formulir deklarasi |
| `ACCESS_NETWORK_STATE` | Tidak ada pengecekan status jaringan. Error koneksi ditangani di `ApiClient` (05 §1) |
| `POST_NOTIFICATIONS` | Belum ada push notification |

### Cek permission di APK akhir

Plugin bisa menambahkan permission lewat manifest merge. Setelah build release:

```bash
flutter build apk --release
$ANDROID_HOME/build-tools/$(ls $ANDROID_HOME/build-tools | tail -1)/aapt2 dump permissions \
  build/app/outputs/flutter-apk/app-release.apk
```

Yang boleh muncul: `android.permission.INTERNET` dan `com.najer.meowville.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (otomatis dari AndroidX). Kalau ada `com.google.android.gms.permission.AD_ID`, jawaban Advertising ID di Play Console (§7) harus disesuaikan, atau hapus dengan `tools:node="remove"`.

## 2. Ikon aplikasi

`pubspec.yaml` sudah punya konfigurasi `flutter_launcher_icons` dengan `assets/icons/icon.png` (1920×1920).

Masalah: `adaptive_icon_foreground` memakai file yang sama dengan ikon penuh. Ikon adaptif memotong sekitar 33% bagian luar, jadi logo bisa terpotong. Buat file `assets/icons/icon_foreground.png` (1024×1024, transparan, logo di tengah dalam area 66%), lalu:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  remove_alpha_ios: true
  image_path: "assets/icons/icon.png"
  adaptive_icon_background: "#C76543"
  adaptive_icon_foreground: "assets/icons/icon_foreground.png"
```

```bash
dart run flutter_launcher_icons
```

Cek di emulator dengan bentuk ikon bulat dan kotak.

Ikon untuk Play Store (512×512) dibuat terpisah dari `icon.png` (§8).

## 3. Signing release

### Buat upload key (sekali saja)

```bash
mkdir -p ~/keys
keytool -genkey -v -keystore ~/keys/meowville-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Simpan password di password manager. Backup file `.jks` ke tempat aman di luar laptop (misalnya Google Drive pribadi). Kalau upload key hilang, bisa diganti lewat Play Console (Play App Signing), tapi prosesnya butuh beberapa hari.

### `android/key.properties`

```properties
storePassword=<password keystore>
keyPassword=<password key>
keyAlias=upload
storeFile=/Users/najer/keys/meowville-upload.jks
```

### `.gitignore` (tambahkan)

```
android/key.properties
*.jks
*.keystore
.env.prod
```

### `android/app/build.gradle.kts`

```kotlin
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.najer.meowville"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.najer.meowville"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
```

### Versi SDK

Dari Flutter yang terpasang (`FlutterExtension.kt`): `compileSdk` 36, `targetSdk` 36, `minSdk` 24. Target 36 memenuhi syarat target API Play untuk aplikasi baru. Tidak perlu diubah.

`applicationId` `com.najer.meowville` permanen setelah upload pertama. Pastikan sudah final.

## 4. Build

### `.env` untuk produksi

`flutter_dotenv` membaca file `.env` yang dibundel sebagai asset. Buat `.env.prod` (di-ignore git) berisi URL dan publishable key project `meowville-prod`, lalu sebelum build:

```bash
cp .env .env.dev
cp .env.prod .env
```

Setelah build, kembalikan dengan `cp .env.dev .env`. Cek isi `.env` sebelum build; kesalahan di sini membuat aplikasi produksi menulis ke database dev.

### Versi

`pubspec.yaml`: `version: 1.0.0+1`. Angka setelah `+` adalah `versionCode` dan wajib naik di setiap upload ke Play, termasuk ke track testing. Contoh: upload kedua `1.0.0+2`, rilis perbaikan `1.0.1+3`.

### Perintah

```bash
flutter clean
flutter pub get
flutter analyze
flutter build appbundle --release \
  --obfuscate --split-debug-info=build/symbols
```

Output: `build/app/outputs/bundle/release/app-release.aab`.

Simpan folder `build/symbols` per versi (misalnya zip ke `~/keys/symbols-1.0.0+1.zip`). Folder ini diperlukan untuk membaca stack trace crash dari build yang di-obfuscate.

### Uji build release di HP sebelum upload

```bash
flutter build apk --release
flutter install --release
```

Wajib dicek di build release, bukan debug: login, buka gambar dari Supabase, upload foto, booking. Masalah R8 atau permission yang hilang hanya muncul di release.

## 5. Supabase produksi

Checklist project `meowville-prod`:

- [ ] Migration 001 sampai 005 dijalankan berurutan (01 §1).
- [ ] Uji T1 sampai T10 dari 01 §8 dijalankan ulang terhadap prod.
- [ ] Setting Auth sesuai 01 §6, termasuk SMTP custom dan template OTP.
- [ ] Akun admin asli dan akun demo dibuat (01 §7).
- [ ] Akun demo owner diberi 1 kucing dan 1 reservasi contoh supaya reviewer melihat isi aplikasi.

Project Supabase free tier di-pause setelah 7 hari tanpa aktivitas. Selama masa review dan closed testing, pastikan ada pemakaian rutin (tester membuka aplikasi), atau pertimbangkan paket berbayar sebelum rilis production.

## 6. Privacy policy dan halaman hapus akun

Play mewajibkan dua URL publik:

1. Privacy policy.
2. Halaman yang menjelaskan cara meminta penghapusan akun dan data, bisa diakses tanpa menginstal aplikasi.

### Hosting dengan GitHub Pages

1. Buat repo publik `meowville-legal`.
2. Isi `index.html` (privacy policy) dan `hapus-akun.html`.
3. Settings > Pages > Deploy from branch `main`, folder root.
4. URL: `https://<username-github>.github.io/meowville-legal/` dan `.../hapus-akun.html`.

### Isi minimal privacy policy

Gunakan isi `legal_screen.dart` sebagai dasar. Harus memuat:

| Bagian | Isi untuk Meowville |
|---|---|
| Identitas | Nama aplikasi Meowville, nama developer sama dengan di Play Console, email kontak |
| Data yang dikumpulkan | Nama, email, nomor HP, foto profil (opsional), data kucing (nama, ras, berat, foto), data reservasi, foto bukti pembayaran, laporan kondisi harian beserta foto |
| Tujuan | Membuat akun, memproses reservasi penitipan, verifikasi pembayaran, laporan kondisi kucing ke pemilik |
| Penyimpanan | Supabase (sebutkan region project), dienkripsi saat transit (HTTPS) |
| Berbagi data | Tidak dijual dan tidak dibagikan ke pihak ketiga. Data hanya dilihat staff Meowville yang berwenang |
| Retensi | Data disimpan selama akun aktif dan dihapus permanen saat akun dihapus |
| Hak pengguna | Mengubah profil di aplikasi, menghapus akun di aplikasi atau lewat email |
| Anak | Aplikasi tidak ditujukan untuk anak di bawah 18 tahun |
| Perubahan kebijakan | Tanggal berlaku dan cara pemberitahuan perubahan |

### Isi halaman hapus akun

- Judul memuat nama aplikasi "Meowville" dan nama developer seperti di Play Console.
- Cara di aplikasi: Akun > Hapus akun > konfirmasi.
- Cara tanpa aplikasi: kirim email dari alamat yang terdaftar ke `<email kontak>` dengan subjek "Hapus akun Meowville". Diproses maksimal 7 hari.
- Data yang dihapus: profil, data kucing, riwayat reservasi, bukti pembayaran, laporan dan foto.
- Data yang disimpan: tidak ada.

Tautkan privacy policy dari layar akun di aplikasi (02 §O7e).

## 7. Play Console: isian App content

Menu: Play Console > aplikasi > Policy > App content (atau checklist "Set up your app" di Dashboard).

| Bagian | Jawaban |
|---|---|
| Privacy policy | URL dari §6 |
| App access | "All or some functionality is restricted". Tambahkan instruksi: akun demo owner dan sitter (email + password) dari 01 §7, beserta catatan "Login dengan email dan password, tidak ada OTP saat login" |
| Ads | No, my app does not contain ads |
| Content rating | Isi kuesioner IARC. Kategori: All other app types. Semua pertanyaan kekerasan, seksual, judi, narkoba: No. Interaksi antar pengguna: No (tidak ada chat). Berbagi lokasi: No. Pembelian digital: No |
| Target audience | 18 and over. Jangan pilih usia anak, supaya tidak terkena kebijakan Families |
| News app | No |
| Data safety | Lihat tabel di bawah |
| Government app | No |
| Financial features | My app doesn't provide any financial features (pembayaran dilakukan di luar aplikasi, aplikasi hanya menerima foto bukti) |
| Health | No health features |
| Advertising ID | No (kecuali §1 menunjukkan `AD_ID` ada di APK) |
| Account deletion | URL halaman hapus akun dari §6 |

### Data safety

Pertanyaan umum:

| Pertanyaan | Jawaban |
|---|---|
| Does your app collect or share any of the required user data types? | Yes |
| Is all of the user data collected by your app encrypted in transit? | Yes |
| Do you provide a way for users to request that their data is deleted? | Yes |

Jenis data:

| Kategori | Data | Collected | Shared | Wajib/opsional | Tujuan |
|---|---|---|---|---|---|
| Personal info | Name | Yes | No | Required | App functionality, Account management |
| Personal info | Email address | Yes | No | Required | App functionality, Account management |
| Personal info | Phone number | Yes | No | Required | App functionality, Account management |
| Photos and videos | Photos | Yes | No | Optional | App functionality |
| Financial info | Purchase history | Yes | No | Required | App functionality |

"Purchase history" mewakili riwayat reservasi kamar. Data diproses di server (bukan hanya di perangkat), jadi semuanya ditandai "collected". Tidak ada yang "shared", karena Supabase berstatus penyedia layanan (service provider) yang memproses data atas nama developer.

## 8. Store listing

Menu: Grow users > Store presence > Main store listing.

| Field | Batas | Isi |
|---|---|---|
| App name | 30 karakter | `Meowville` |
| Short description | 80 karakter | `Titip kucing jadi mudah: booking kamar dan pantau laporan harian anabul.` |
| Full description | 4000 karakter | Draf di bawah |
| App icon | 512×512 PNG 32-bit, maks 1 MB | Turunkan dari `assets/icons/icon.png` |
| Feature graphic | 1024×500 JPG atau PNG tanpa transparansi | Logo + tagline di atas warna `#C76543` |
| Phone screenshots | 2 sampai 8, rasio 16:9 atau 9:16, sisi 320 sampai 3840 px | Ambil dari emulator Pixel: katalog kamar, alur reservasi, detail booking, laporan harian, dashboard admin |
| App category | | Lifestyle |
| Contact email | | email kontak yang sama dengan privacy policy |

Draf full description:

```
Meowville adalah aplikasi penitipan kucing yang menghubungkan pemilik kucing dengan pet hotel.

Untuk pemilik kucing:
- Simpan profil kucing lengkap dengan foto, ras, dan berat badan
- Lihat katalog tipe kamar beserta fasilitas dan harga per malam
- Pesan kamar, pilih tanggal, dan tambahkan layanan seperti grooming atau antar jemput
- Unggah bukti pembayaran langsung dari aplikasi
- Pantau status reservasi dari menunggu konfirmasi sampai selesai
- Terima laporan harian kondisi kucing: makan, minum, mood, catatan, dan foto

Untuk staff pet hotel:
- Kelola check-in dan check-out kucing setiap hari
- Kirim laporan kondisi harian dengan foto

Untuk admin pet hotel:
- Konfirmasi atau tolak reservasi dan tetapkan unit kamar
- Kelola tipe kamar, unit yang diblokir, dan layanan tambahan
- Pantau ketersediaan kamar lewat kalender
- Lihat laporan jumlah booking dan pendapatan
- Buat akun untuk staff

Data kamu tersimpan aman dan bisa dihapus kapan saja dari menu Akun.
```

## 9. Rilis lewat track testing

### Internal testing (hari 3, sebelum submit)

1. Testing > Internal testing > Create new release.
2. Play App Signing: terima default (Google menyimpan app signing key, kamu memegang upload key dari §3).
3. Upload `app-release.aab`. Release name otomatis `1 (1.0.0)`.
4. Release notes (id-ID): `Rilis pertama Meowville.`
5. Save > Review release > Start rollout to Internal testing.
6. Tab Testers: buat email list berisi akun Google sendiri dan tim. Salin opt-in link, buka di HP, install dari Play Store.
7. Jalankan skenario §10 di aplikasi yang diinstal dari Play.

Internal testing biasanya tersedia dalam hitungan menit dan tidak menunggu review penuh.

### Closed testing (akun developer personal)

Syarat akun personal yang dibuat setelah 13 November 2023: minimal 12 tester ikut closed testing terus-menerus selama 14 hari sebelum bisa mengajukan akses Production.

1. Testing > Closed testing > Create track (atau pakai track "Alpha").
2. Testers: Google Group atau email list berisi minimal 12 akun Google (teman sekelas, dosen, keluarga). Tambahkan lebih dari 12 sebagai cadangan.
3. Countries/regions: Indonesia.
4. Promote release dari internal testing, atau upload AAB baru dengan `versionCode` lebih tinggi.
5. Send for review. Review pertama bisa makan beberapa hari.
6. Setelah disetujui, bagikan opt-in link ke tester. Minta mereka install dan membuka aplikasi beberapa kali selama 14 hari.
7. Setelah 14 hari: Dashboard > Apply for production, isi kuesioner tentang hasil testing.

Jadi target "diunggah dalam 3 hari" tercapai di closed testing. Rilis publik di Production paling cepat sekitar 15 hari setelah closed testing disetujui.

### Akun organisasi

Langsung Production > Create new release, upload, Send for review.

## 10. Skenario uji end-to-end

Jalankan di HP fisik dengan build release, memakai project Supabase yang akan dipakai (dev untuk D2-11, prod untuk D3-06).

| # | Role | Langkah | Hasil yang diharapkan |
|---|---|---|---|
| E1 | Owner baru | Registrasi, verifikasi email, login | Masuk ke beranda owner |
| E2 | Owner | Tambah kucing dengan foto dari kamera | Kucing tampil dengan foto |
| E3 | Owner | Booking Standard 2 malam + 1 addon, unggah bukti bayar | Status menunggu konfirmasi, total benar |
| E4 | Admin | Buka dashboard | Reservasi E3 tampil di pending, bukti bayar bisa dibuka |
| E5 | Admin | Approve dengan unit S1 | Status terkonfirmasi, kalender berkurang 1 |
| E6 | Owner | Refresh riwayat | Status terkonfirmasi, unit S1 |
| E7 | Sitter | Check-in reservasi E3 (tanggal check-in hari ini) | Pindah ke sedang menginap |
| E8 | Sitter | Kirim laporan harian dengan foto | Tampil di riwayat sitter |
| E9 | Owner | Buka laporan kucing | Laporan E8 tampil dengan foto dan nama sitter |
| E10 | Sitter | Check-out | Status selesai |
| E11 | Admin | Laporan bulan ini | Booking dan pendapatan bertambah sesuai E3 |
| E12 | Admin | Buat akun sitter baru | Sitter baru bisa login setelah verifikasi email |
| E13 | Admin | Block unit S2 untuk 3 hari | Kalender berkurang, owner tidak bisa booking kalau semua unit habis |
| E14 | Owner | Booking lalu batalkan | Status dibatalkan, slot kembali |
| E15 | Owner | Lupa password dengan kode OTP | Login dengan password baru berhasil |
| E16 | Owner | Hapus akun | Kembali ke login, email bisa daftar ulang |
| E17 | Semua | Matikan internet, buka daftar | Pesan "Tidak ada koneksi internet", tombol coba lagi berfungsi setelah internet nyala |
| E18 | Semua | Login dengan "Ingat saya", tutup paksa aplikasi, buka lagi | Langsung masuk tanpa login ulang |
| E19 | Semua | Logout, login role lain di HP yang sama | Tidak ada data akun sebelumnya yang terlihat |

## 11. Setelah upload

- Pantau Play Console > Inbox dan email untuk hasil review atau penolakan. Penolakan biasanya menyebut kebijakan yang dilanggar; perbaiki lalu upload dengan `versionCode` baru.
- Pantau Quality > Android vitals > Crashes and ANRs selama testing.
- Setiap perbaikan: naikkan versi, build ulang, upload ke track yang sama.
