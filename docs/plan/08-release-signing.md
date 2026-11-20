# 08. Signing release dan build AAB

Panduan lengkap dari nol sampai AAB siap diunggah ke Play Console. Semua langkah dijalankan manual di laptop pemilik. Tidak ada secret yang masuk repo.

## 1. Konsep singkat

| Istilah | Arti untuk Meowville |
|---|---|
| **Upload key** | Kunci milikmu untuk menandatangani AAB sebelum diunggah. Disimpan di file `.jks` di laptop. |
| **App signing key** | Kunci yang dipegang Google (Play App Signing). Google menandatangani ulang APK yang diterima user dengan kunci ini. |
| **`key.properties`** | File lokal berisi lokasi `.jks` dan password-nya. Dibaca Gradle saat build release. Tidak pernah di-commit. |
| **`signingConfigs.release`** | Blok di `android/app/build.gradle.kts` yang memakai isi `key.properties`. |

Alurnya: build AAB dengan upload key → unggah ke Play → Google memverifikasi upload key → Google menandatangani dengan app signing key → user mengunduh.

Kalau upload key hilang, Google bisa menggantinya (lewat formulir di Play Console, butuh beberapa hari). Kalau app signing key hilang, app tidak bisa diperbarui lagi. Itulah alasan app signing key diserahkan ke Google.

## 2. Status repo saat ini

- `android/app/build.gradle.kts` **belum** dikonfigurasi: build release masih ditandatangani debug key (`signingConfig = signingConfigs.getByName("debug")`). Bagian ini sengaja dikerjakan manual sesuai §4.2.
- `android/.gitignore` sudah mengabaikan `key.properties`, `*.jks`, dan `*.keystore`.
- Template `android/key.properties.example` tersedia di working tree (belum di-commit).

Setelah §4.2 selesai, tanpa `key.properties` build release akan **gagal** dengan pesan `SigningConfig "release" is missing required property "storeFile"`. Ini disengaja, supaya AAB bertanda tangan debug tidak bisa dibuat dan terunggah.

## 3. Langkah 1: buat upload keystore (sekali seumur app)

```bash
mkdir -p ~/keys
keytool -genkey -v \
  -keystore ~/keys/meowville-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Isian yang diminta:

| Pertanyaan | Isi |
|---|---|
| Keystore password | Password kuat, simpan di password manager |
| First and last name | Nama developer atau organisasi |
| Organizational unit / Organization | Nama organisasi sesuai Play Console |
| City, State, Country code | Kota, provinsi, `ID` |
| Key password | Boleh sama dengan keystore password (tekan Enter) |

Cek hasilnya:

```bash
keytool -list -v -keystore ~/keys/meowville-upload.jks -alias upload | grep -E "Owner|SHA1|SHA256|Valid"
```

**Backup segera:** salin `~/keys/meowville-upload.jks` ke dua tempat di luar laptop (misalnya Google Drive pribadi dan flashdisk). Simpan password-nya di password manager. Jangan kirim lewat chat dan jangan masukkan ke repo.

## 4. Langkah 2: konfigurasi Gradle

### 4.1 `android/key.properties`

```bash
cp android/key.properties.example android/key.properties
```

Isi:

```properties
storePassword=<password keystore>
keyPassword=<password key>
keyAlias=upload
storeFile=/Users/najer/keys/meowville-upload.jks
```

Pastikan tidak ikut git:

```bash
git check-ignore -v android/key.properties
# harus muncul: android/.gitignore:...:key.properties
git status --short android/   # key.properties tidak boleh muncul
```

### 4.2 `android/app/build.gradle.kts`

Ubah file menjadi seperti ini (bagian yang ditambahkan: `import`, `keystoreProperties`, `signingConfigs`, dan `buildTypes.release`):

```kotlin
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload key untuk Play App Signing. File ini tidak di-commit (lihat android/.gitignore).
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    // ... namespace, compileSdk, defaultConfig tetap ...

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

Penjelasan:

- `rootProject.file("key.properties")` menunjuk ke `android/key.properties`, karena root project Gradle adalah folder `android/`.
- `signingConfigs` harus ditulis **sebelum** `buildTypes`, karena `getByName("release")` mencari config yang sudah dibuat.
- Tidak ada fallback ke debug key. Jika file tidak ada, build release gagal; build debug (`flutter run`) tetap jalan normal.

## 5. Langkah 3: siapkan build

### 5.1 Versi

`pubspec.yaml`:

```yaml
version: 1.0.0+1
```

Angka setelah `+` adalah `versionCode`. Nilainya wajib naik di **setiap** upload ke Play, termasuk ke track testing. Contoh: upload kedua `1.0.0+2`, rilis perbaikan `1.0.1+3`.

`applicationId` `com.najer.meowville` permanen setelah upload pertama.

### 5.2 `.env`

`.env` ikut terbungkus di AAB. Pastikan berisi project production dengan URL `https`, dan hanya publishable key:

```bash
grep -c '^SUPABASE_URL=https://' .env      # harus 1
grep -c 'sb_publishable_' .env             # harus 1
grep -ciE 'service_role|sb_secret' .env    # harus 0
```

Jangan pernah build rilis memakai `.env` lokal (`http://10.0.2.2:54321`).

### 5.3 Cek kualitas

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
```

## 6. Langkah 4: build AAB

```bash
flutter build appbundle --release \
  --obfuscate --split-debug-info=build/symbols
```

Output: `build/app/outputs/bundle/release/app-release.aab`.

- `--obfuscate` menyamarkan nama kelas dan fungsi Dart.
- `--split-debug-info` memisahkan simbol Dart ke `build/symbols`. Arsipkan folder ini per versi, karena diperlukan untuk membaca stack trace dari build yang di-obfuscate:

```bash
mkdir -p ~/keys/symbols
zip -r ~/keys/symbols/meowville-1.0.0+1.zip build/symbols build/app/outputs/mapping/release/mapping.txt
```

## 7. Langkah 5: verifikasi sebelum upload

```bash
AAB=build/app/outputs/bundle/release/app-release.aab

# Tanda tangan: harus CN dari keystore-mu, BUKAN "Android Debug"
keytool -printcert -jarfile $AAB | grep -E "Owner|SHA256"

# Permission dan flag manifest (lewat APK release)
flutter build apk --release
BT=~/Library/Android/sdk/build-tools/36.0.0
APK=build/app/outputs/flutter-apk/app-release.apk
$BT/aapt2 dump permissions $APK
#   harus: android.permission.INTERNET dan DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION saja
$BT/aapt2 dump badging $APK | grep -E "package:|application-label|targetSdk"
#   harus: versionCode sesuai pubspec, label 'Meowville', targetSdkVersion:'36'
$BT/aapt2 dump xmltree --file AndroidManifest.xml $APK | grep -E "allowBackup|debuggable"
#   harus: allowBackup=false, tidak ada debuggable=true

# 16 KB page size
$BT/zipalign -c -P 16 -v 4 $APK | tail -1
#   harus: Verification successful
```

Uji di HP fisik sebelum upload:

```bash
flutter install --release
```

Cek minimal: login, lupa kata sandi (kode 6 digit datang), tambah kucing dengan foto, booking + unggah bukti, buka bukti dari akun admin, hapus akun.

## 8. Langkah 6: Play App Signing dan upload pertama

1. Play Console > buat app (nama "Meowville", bahasa default Indonesia, App, Free).
2. Testing > **Internal testing** > Create new release.
3. Bagian App integrity: pilih **Use Google-generated key** (Play App Signing). Google menyimpan app signing key; upload key-mu dipakai untuk unggahan berikutnya.
4. Unggah `app-release.aab`. Play memeriksa tanda tangan, versi, target SDK, dan 16 KB.
5. Isi release notes, lalu Save > Review release > Start rollout.
6. Setelah upload pertama, buka **Setup > App signing**. Catat SHA-1 dan SHA-256 untuk **upload key** dan **app signing key**. Keduanya diperlukan jika kelak memakai Google Sign-In, App Links (`assetlinks.json`), atau API Google lain.
7. Unggah simbol: App bundle explorer > versi > Downloads > upload `mapping.txt` (jika Play tidak mengambilnya otomatis dari AAB) dan native debug symbols.

## 9. Rilis berikutnya

```bash
# naikkan versionCode di pubspec.yaml, misalnya 1.0.0+2
flutter clean && flutter pub get
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab | grep Owner
```

Upload ke track yang sama dengan `versionCode` lebih tinggi.

## 10. Troubleshooting

| Gejala | Penyebab dan solusi |
|---|---|
| `SigningConfig "release" is missing required property "storeFile"` | `android/key.properties` tidak ada atau `storeFile` kosong. Buat sesuai §4.1. |
| `Keystore was tampered with, or password was incorrect` | `storePassword` salah. |
| `Cannot recover key` | `keyPassword` salah, atau alias berbeda. Cek dengan `keytool -list -keystore … `. |
| `KeytoolException: … not found` / path error | `storeFile` harus path absolut dan tanpa tanda kutip. `~` tidak diekspansi; tulis `/Users/najer/...`. |
| Play: "You uploaded an APK or Android App Bundle that was signed in debug mode" | AAB dibuat tanpa signing release. Jalankan ulang §6 dan cek §7. |
| Play: "Version code 1 has already been used" | Naikkan angka setelah `+` di `pubspec.yaml`. |
| Play: "Your app bundle is signed with the wrong key" | AAB ditandatangani keystore lain. Pakai `.jks` yang sama dengan upload pertama, atau minta reset upload key di Setup > App signing. |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` saat `flutter install` | Di HP sudah ada versi dengan tanda tangan lain (misalnya debug). Uninstall dulu. |

## 11. Checklist keamanan

- [ ] `meowville-upload.jks` ada di dua backup di luar laptop.
- [ ] Password keystore di password manager.
- [ ] `git status` tidak pernah menampilkan `key.properties`, `.jks`, atau `.env`.
- [ ] Folder `build/symbols` + `mapping.txt` diarsipkan per versi.
- [ ] SHA-1 dan SHA-256 upload key serta app signing key dicatat.
