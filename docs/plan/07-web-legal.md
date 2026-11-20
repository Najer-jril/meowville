# 07. Situs legal Meowville (`meowville.najer.dev`)

Brief untuk repo terpisah `papb/meowville-web`. Situs ini memenuhi syarat Google Play (privacy policy dan halaman hapus akun), menjadi tujuan link verifikasi email Supabase, dan menjadi kanal kontak support. Situs ini bukan web app: semua halamannya statis, tanpa login, tanpa cookie, tanpa analytics.

**Untuk agen yang membangun repo:** kerjakan §2–§6 dan §4A (desain), lalu cek §9. Aset di §4A.1 disalin dari `../meowville`. Bagian §7 dan §8 adalah konfigurasi dashboard yang dikerjakan manual oleh pemilik, bukan tugas agen. Isian `{{…}}` dibiarkan sebagai placeholder yang mudah dicari, kecuali `{{EMAIL_SUPPORT}}` = `meowville@najer.dev`.

## 1. Keputusan yang sudah diambil

| Hal | Keputusan |
|---|---|
| Domain | `meowville.najer.dev` (subdomain dari `najer.dev`) |
| Hosting | Cloudflare Pages |
| Repo | Terpisah: `papb/meowville` (Flutter) dan `papb/meowville-web` (situs ini) |
| Status app | Mode demo. Belum ada mitra pet hotel asli, tidak ada transaksi nyata |
| Nomor HP | Tidak dikumpulkan lagi (kolom `profiles.phone` di-drop) |
| Kontak | Email support di domain sendiri, diteruskan ke inbox pribadi (§8) |

Repo terpisah adalah pilihan yang tepat. Siklus rilisnya berbeda: teks legal bisa diperbarui tanpa build Flutter, dan Cloudflare Pages cukup membangun repo kecil tanpa SDK Flutter. Menggabungkan ke repo Flutter juga bisa (Pages mendukung *root directory* `web/`), tetapi setiap commit Flutter akan memicu build situs.

## 2. Tech stack

| Lapisan | Pilihan | Alasan |
|---|---|---|
| Generator | **Astro 5** (`output: 'static'`) | Konten ditulis di Markdown, hasilnya HTML murni tanpa JavaScript di browser. Mudah diubah oleh siapa pun. |
| Konten | Markdown di `src/content/` | Satu file per dokumen legal, dengan frontmatter `title` dan `updated`. |
| Styling | CSS biasa, satu file `src/styles/global.css` | Tanpa framework. Halamannya hanya dokumen teks. |
| Font | Plus Jakarta Sans, file `.woff2` di `public/fonts/` (self-hosted) | Sama dengan app. Tidak memanggil Google Fonts, sehingga tidak ada data pengunjung ke pihak ketiga. |
| Hosting | Cloudflare Pages, build otomatis dari branch `main` | Gratis, HTTPS otomatis, preview per branch. |
| Node | 20 LTS atau lebih baru | Set `NODE_VERSION=20` di environment Pages. |

Alternatif yang lebih minimal: lima file HTML tanpa build step. Ini sah, tetapi setiap perubahan header/footer harus diulang di semua file. Astro tetap ringan dan menghindari duplikasi itu.

## 3. Struktur repo

```
meowville-web/
├── astro.config.mjs          # site: 'https://meowville.najer.dev', output: 'static', trailingSlash: 'never'
├── package.json
├── public/
│   ├── _headers              # header keamanan (§6)
│   ├── _redirects            # alias URL (§6)
│   ├── favicon.svg
│   ├── icon-512.png          # sama dengan ikon Play
│   ├── fonts/PlusJakartaSans-*.woff2
│   └── robots.txt
├── src/
│   ├── content/
│   │   ├── privacy.md
│   │   ├── terms.md
│   │   └── delete-account.md
│   ├── layouts/Base.astro    # <head>, header, footer, lang="id"
│   ├── pages/
│   │   ├── index.astro
│   │   ├── privacy.astro
│   │   ├── terms.astro
│   │   ├── hapus-akun.astro
│   │   ├── verified.astro
│   │   └── 404.astro
│   └── styles/global.css
└── README.md                 # cara build, deploy, dan siapa yang mengubah konten
```

## 4. Halaman

Semua halaman: `lang="id"`, satu kolom maksimal 720 px, terbaca di layar 360 px, kontras AA, tanpa cookie banner (karena tidak ada cookie). Footer di setiap halaman: tautan Privasi · Ketentuan · Hapus akun · email support · "© 2026 {{NAMA_DEVELOPER}}".

| URL | Isi | Dipakai oleh |
|---|---|---|
| `/` | Nama dan ikon Meowville, satu kalimat deskripsi, **banner demo** (§5), tautan ke tiga dokumen, email support. Tanpa tombol unduh sampai app terbit. | Store listing (website), umum |
| `/privacy` | Kebijakan privasi (§5.1) | Play Console > Privacy policy, layar Akun dan Registrasi di app |
| `/terms` | Ketentuan layanan. Pindahan isi `lib/screens/auth/legal_screen.dart`, disesuaikan: pembatalan hanya untuk status Menunggu, kontak lewat email (bukan WhatsApp), dan pernyataan mode demo. | Layar Registrasi |
| `/hapus-akun` | Cara menghapus akun dan data (§5.2) | Play Console > Data deletion, layar Akun |
| `/verified` | "Email berhasil diverifikasi. Silakan kembali ke aplikasi Meowville dan masuk." Tanpa JavaScript. | Supabase Site URL (§7) |
| `/404` | Halaman tidak ditemukan + tautan ke beranda | Cloudflare Pages |

### 4.1 Catatan `/verified`

Supabase mengarahkan link verifikasi ke Site URL dengan token di fragment (`#access_token=…`). Fragment tidak dikirim ke server, dan halaman ini tidak memuat JavaScript, sehingga token tidak dibaca atau dikirim ke mana pun. Header `Referrer-Policy: no-referrer` (§6) mencegah URL lengkap bocor ke tautan keluar. Jika suatu saat signup memakai OTP, halaman ini tetap berguna sebagai Site URL cadangan.

## 4A. Desain UI (harus terlihat seperti app Flutter)

Situs ini adalah versi web dari layar legal di app (`lib/widgets/legal_document.dart`), dengan token dari `lib/theme/app_theme.dart`. Mode terang saja, sama seperti app (`color-scheme: light`).

### 4A.1 Aset yang disalin dari repo Flutter

| Dari `papb/meowville` | Ke `meowville-web/public/` | Dipakai di |
|---|---|---|
| `assets/icons/icon.png` | `icon-512.png`, `apple-touch-icon.png` (180 px) | favicon, header |
| `assets/images/logo.png` | `logo.png` | header, beranda |
| `assets/svg/cat_village.svg` | `svg/cat_village.svg` | dekorasi di atas kartu (seperti login) |
| `assets/svg/envelope_cat.svg` | `svg/envelope_cat.svg` | `/verified` |
| `assets/svg/big_paw.svg`, `small_paw.svg` | `svg/` | aksen beranda dan 404 |
| Plus Jakarta Sans 400, 600, 700 (`.woff2`, dari `@fontsource/plus-jakarta-sans` atau Google Fonts download) | `fonts/` | semua teks |

Ikon UI memakai **Material Symbols Rounded**, sama dengan keluarga ikon Material di Flutter. Salin hanya path SVG yang dipakai (`arrow_back`, `chevron_right`, `policy`, `gavel`, `delete_forever`, `mail`, `info`, `mark_email_read`) sebagai inline SVG. Jangan memuat font ikon dari CDN.

### 4A.2 Token CSS (`src/styles/global.css`)

```css
:root {
  color-scheme: light;

  /* AppColors */
  --primary: #0F766E;
  --primary-soft: #CCEFEA;
  --primary-muted: #80D5CB;
  --primary-deep: #00504A;
  --secondary: #F59E6B;
  --secondary-soft: #FFE4D2;
  --accent: #FFC94D;
  --bg: #FAF8F4;
  --surface: #FFFFFF;
  --surface-alt: #F0EEE8;
  --border: #E5E7EB;
  --text: #1F2937;
  --muted: #6B7280;
  --success: #16A34A;
  --success-soft: #DCFCE7;
  --warning: #D97706;
  --warning-soft: #FEF3C7;
  --danger: #DC2626;
  --danger-soft: #FEE2E2;
  --info: #0284C7;
  --info-soft: #E0F2FE;

  /* AppRadius */
  --radius-card: 20px;
  --radius-button: 16px;
  --radius-input: 14px;
  --radius-pill: 999px;

  /* AppSpacing */
  --space-xs: 4px;
  --space-sm: 8px;
  --space-md: 12px;
  --space-lg: 16px;
  --space-xl: 24px;
  --space-page: 20px;

  /* AppShadows.soft = BoxShadow(0x140F766E, offset 0 4, blur 16) */
  --shadow-soft: 0 4px 16px rgba(15, 118, 110, 0.08);
  --shadow-bar: 0 -4px 16px rgba(15, 118, 110, 0.06);

  --font: "Plus Jakarta Sans", system-ui, sans-serif;
  --content-max: 720px;
}

body {
  margin: 0;
  background: var(--bg);
  color: var(--text);
  font: 400 16px/1.45 var(--font);
}
```

### 4A.3 Tipografi

| Peran | Ukuran / tebal / line-height | Warna | Sumber di Flutter |
|---|---|---|---|
| Display (judul beranda, `/verified`) | 32 px mobile, 40 px ≥768 px / 600 / 1.15, `letter-spacing: -0.02em` | `--text` | `AppText.display` |
| Judul header halaman | 20 / 700 | `--text` | `LegalDocument._Header` |
| Overline | 12 / 700, `letter-spacing: 0.08em` | `--primary` | `_IntroCard` overline |
| Judul dokumen | 22 / 700 / 1.25 | `--text` | `_IntroCard` title |
| Subjudul | 15 / 400 / 1.375 | `--muted` | `_IntroCard` subtitle |
| Judul pasal | 16 / 700; nomor `01`, `02` berwarna `--primary` | `--text` | `_Pasal` |
| Isi pasal | 15 / 400 / 24 px | `--text` | `_Pasal` body |
| Kecil (tanggal, footer) | 13 / 400 | `--muted` | `bodySmall` |
| Tombol | 16 / 700 | — | `FilledButton` |

### 4A.4 Komponen

- **Card**: background `--surface`, radius 20, padding 20, `box-shadow: var(--shadow-soft)`, tanpa border.
- **Header halaman**: baris berisi tombol bulat 44 px (putih, shadow soft, ikon `arrow_back` 20 px) yang menuju `/`, lalu judul 20/700. Di beranda, tombol bulat diganti logo 44 px.
- **Intro card** (di atas setiap dokumen): kolom kiri berisi overline, judul, subjudul, dan "Diperbarui {{tanggal}}". Kanan atas: lingkaran 40 px `--primary-soft` dengan ikon 20 px `--primary`. Overline: Privasi untuk `/privacy`, Ketentuan untuk `/terms`, Akun untuk `/hapus-akun`.
- **Pasal**: setiap `##` di Markdown dirender sebagai baris `01  Judul ———` (nomor primary, judul, garis 1 px `--border` mengisi sisa lebar), lalu isi di bawahnya. Jarak antar pasal 20 px. Nomor dibuat otomatis lewat CSS counter, bukan ditulis manual di Markdown.
- **Tombol primary**: tinggi minimal 52, radius 16, background `--primary`, teks putih 16/700. Hover memakai `--primary-deep`. Tombol outline: border 1.5 px `--primary`, teks `--primary`.
- **List tile tautan** (beranda, seperti menu Akun di app): card berisi lingkaran ikon 40 px `--primary-soft`, judul 16/600, deskripsi 13 muted, dan `chevron_right` di kanan. Seluruh card bisa diklik, area sentuh minimal 48 px.
- **Banner demo**: background `--warning-soft`, teks `--text`, label tebal "Aplikasi demo." berwarna `--warning`, ikon `info`, radius 14, padding 16.
- **Dekorasi**: `cat_village.svg` lebar 100% maksimal 390 px, rata tengah, tepat di atas card utama, dengan opacity sekitar 0.35 seperti di layar login. Hanya dekorasi: `aria-hidden="true"`, `alt=""`.
- **Fokus keyboard**: `outline: 2px solid var(--primary); outline-offset: 2px` untuk semua elemen interaktif.

### 4A.5 Wireframe

Halaman dokumen (`/privacy`, `/terms`, `/hapus-akun`):

```
(←)  Kebijakan Privasi
         ⌂ ⌂ ⌂ ⌂ ⌂            ← cat_village.svg
┌──────────────────────────────┐
│ PRIVASI                  (🛡)│
│ Kebijakan Privasi Meowville  │
│ Data apa yang kami simpan …  │
│ Diperbarui 20 November 2026  │
└──────────────────────────────┘
┌──────────────────────────────┐
│ ⚠ Aplikasi demo. …           │  ← banner demo (di dalam atau di atas card)
│ 01 Siapa kami ────────────── │
│ Meowville dikembangkan …     │
│ 02 Data yang kami kumpulkan ─│
│ …                            │
└──────────────────────────────┘
Privasi · Ketentuan · Hapus akun · meowville@najer.dev
© 2026 {{NAMA_DEVELOPER}}
```

Beranda (`/`):

```
[logo]
Meowville                         ← display
Rumah kedua yang nyaman untuk kucing.
┌ ⚠ Aplikasi demo … ─────────────┐
┌ (🛡) Kebijakan Privasi       › ┐
┌ (§)  Ketentuan Layanan       › ┐
┌ (🗑) Hapus Akun              › ┐
┌ (✉)  meowville@najer.dev     › ┐  ← mailto:
```

`/verified` (meniru layar "Kode Berhasil Dikirim" di app):

```
        [envelope_cat.svg]
     Email Terverifikasi           ← display, rata tengah
  Akun kamu sudah aktif. Kembali ke
  aplikasi Meowville lalu masuk.
┌──────────────────────────────┐   ← card --success-soft
│  ✓ Verifikasi berhasil       │
└──────────────────────────────┘
```

Halaman `/verified` tidak punya tombol "Buka aplikasi" sampai App Links dipasang.

### 4A.6 Responsif

- Kolom konten `max-width: var(--content-max)`, rata tengah, padding samping 20 px.
- Di bawah 768 px semua elemen satu kolom. Tidak ada scroll horizontal di lebar 320 px.
- Teks tetap rapi saat zoom browser 200%. Jangan memakai tinggi tetap pada tombol atau card (pelajaran dari temuan M14 di app).

## 5. Konten

Tandai bagian yang perlu diisi dengan `{{…}}`. Banner demo dipasang di `/`, `/privacy`, dan `/terms`:

> **Aplikasi demo.** Meowville saat ini adalah proyek demonstrasi tanpa mitra pet hotel asli. Tidak ada layanan penitipan atau transaksi pembayaran nyata. Jangan mentransfer uang ke rekening yang tampil di aplikasi.

### 5.1 Kebijakan privasi (`privacy.md`)

Bagian wajib, sesuai kode aktual setelah kolom `phone` di-drop:

1. **Siapa kami.** Meowville, dikembangkan oleh {{NAMA_DEVELOPER, sama persis dengan nama di Play Console}}. Kontak: {{EMAIL_SUPPORT}}. Tanggal berlaku: {{TANGGAL}}.
2. **Data yang kami kumpulkan.**
   - Akun: nama, alamat email, kata sandi (disimpan dalam bentuk hash oleh penyedia autentikasi), ID akun.
   - Foto profil (opsional).
   - Data kucing: nama, ras, berat, foto (opsional).
   - Reservasi: tanggal, tipe kamar, layanan tambahan, harga, status.
   - Foto bukti pembayaran. Bisa memuat nama bank dan nomor rekening; dalam mode demo, unggah gambar apa pun.
   - Laporan harian yang dibuat staf: catatan makan, minum, mood, dan foto kucing.
   - Data yang **tidak** dikumpulkan: lokasi, kontak, nomor telepon, ID iklan, data perangkat, riwayat penggunaan untuk analitik.
3. **Izin perangkat.** App tidak meminta izin kamera atau galeri. Foto diambil lewat aplikasi kamera sistem atau pemilih foto Android, dan hanya foto yang dipilih user yang diunggah.
4. **Tujuan.** Membuat dan mengelola akun, memproses reservasi, verifikasi pembayaran oleh admin, mengirim laporan kondisi kucing ke pemilik, dan mengirim email akun (verifikasi, reset kata sandi).
5. **Siapa yang bisa melihat.** Pemilik melihat datanya sendiri. Admin dan pet sitter Meowville melihat data reservasi yang mereka tangani. Bukti pembayaran hanya bisa dilihat pemiliknya dan admin.
6. **Penyedia layanan (pemroses data).** Data tidak dijual dan tidak dibagikan untuk iklan.
   - Supabase: database, autentikasi, penyimpanan file, region {{REGION_SUPABASE}}.
   - Resend: pengiriman email akun.
   - Cloudflare: hosting situs ini; tidak menyimpan data akun.
7. **Keamanan.** Semua koneksi memakai HTTPS. Akses data dibatasi per akun di level database (Row Level Security). Bukti pembayaran disimpan di penyimpanan privat.
8. **Retensi dan penghapusan.** Data disimpan selama akun aktif. Saat akun dihapus, profil, data kucing, reservasi, laporan, dan semua foto dihapus permanen. Cara menghapus: lihat `/hapus-akun`.
9. **Hak pengguna.** Melihat dan mengubah profil di app, menghapus akun, dan meminta salinan atau penghapusan data lewat email.
10. **Anak.** Layanan ditujukan untuk pengguna berusia 18 tahun ke atas. Kami tidak dengan sengaja mengumpulkan data anak.
11. **Perubahan kebijakan.** Perubahan diumumkan di halaman ini dengan tanggal berlaku yang baru.

### 5.2 Hapus akun (`delete-account.md`, halaman `/hapus-akun`)

Judul harus memuat nama app dan nama developer sesuai Play Console, misalnya "Hapus akun Meowville — {{NAMA_DEVELOPER}}".

1. **Dari aplikasi:** Akun → Hapus akun → konfirmasi. Untuk pemilik, batalkan atau selesaikan dulu reservasi yang masih aktif.
2. **Tanpa aplikasi:** kirim email dari alamat yang terdaftar ke {{EMAIL_SUPPORT}} dengan subjek "Hapus akun Meowville". Permintaan diproses paling lambat 7 hari, dan kami membalas setelah selesai.
3. **Data yang dihapus:** akun dan profil, data dan foto kucing, riwayat reservasi, bukti pembayaran, laporan harian dan fotonya, foto profil.
4. **Data yang disimpan:** tidak ada. Jika nanti memakai backup terjadwal: salinan cadangan terhapus otomatis dalam {{N}} hari.

## 6. Konfigurasi Cloudflare Pages

**Build:** Framework preset Astro, build command `npm run build`, output `dist`, env `NODE_VERSION=20`.

**Domain:** Pages > Custom domains > `meowville.najer.dev`. Jika DNS `najer.dev` sudah di Cloudflare, CNAME dibuat otomatis.

`public/_headers`:

```
/*
  Strict-Transport-Security: max-age=31536000; includeSubDomains
  X-Content-Type-Options: nosniff
  X-Frame-Options: DENY
  Referrer-Policy: no-referrer
  Permissions-Policy: camera=(), microphone=(), geolocation=()
  Content-Security-Policy: default-src 'self'; img-src 'self' data:; style-src 'self'; font-src 'self'; script-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'
```

`public/_redirects` (alias berbahasa Inggris dan typo umum):

```
/privacy-policy   /privacy     301
/delete-account   /hapus-akun  301
/hapus            /hapus-akun  301
```

`robots.txt`: izinkan semua kecuali `/verified` (`Disallow: /verified`).

## 7. Integrasi dengan Supabase dan app

| Tempat | Nilai |
|---|---|
| Supabase > Authentication > URL Configuration > Site URL | `https://meowville.najer.dev/verified` |
| Supabase > Redirect URLs | `https://meowville.najer.dev/**` |
| Play Console > App content > Privacy policy | `https://meowville.najer.dev/privacy` |
| Play Console > App content > Data deletion | `https://meowville.najer.dev/hapus-akun` |
| Play Console > Store listing > Website | `https://meowville.najer.dev` |
| Play Console > Store listing > Email | {{EMAIL_SUPPORT}} |
| App Flutter | Konstanta URL di satu file. Layar Akun (owner, sitter, admin) dan Registrasi membuka `/privacy`, `/terms`, `/hapus-akun`. Email support dan data bank demo dibaca dari tabel `app_settings`. |

## 8. Email: kirim lewat Resend, terima lewat Cloudflare Email Routing

Bagian ini dikerjakan manual di dashboard, bukan oleh AI di repo web. Semuanya gratis dan memakai domain `najer.dev`, sehingga email pribadi tidak pernah tampil ke user.

**Istilah singkat:**
- **SMTP** adalah "kantor pos" yang dipakai Supabase untuk mengirim email.
- **Resend** adalah penyedia SMTP. Supabase menitipkan email ke Resend, lalu Resend mengirimkannya atas nama `najer.dev`.
- Record DNS **SPF** dan **DKIM** membuktikan ke Gmail bahwa Resend boleh mengirim atas nama domain ini. Tanpa keduanya, email masuk spam atau ditolak.

**Syarat:** DNS `najer.dev` dikelola di Cloudflare (nameserver mengarah ke Cloudflare). Cek di dash.cloudflare.com: `najer.dev` harus muncul dengan status *Active*. Syarat ini juga diperlukan untuk Cloudflare Pages dan Email Routing.

### 8.1 Resend (mengirim email)

1. Daftar di resend.com (login dengan GitHub boleh).
2. **Domains > Add Domain**: isi `najer.dev`, pilih region terdekat (Tokyo `ap-northeast-1` jika tersedia).
3. Pakai tombol **Auto configure** (Cloudflare). Resend menambahkan record ke DNS `najer.dev` secara otomatis. Per November 2026 record-nya:
   - `TXT` `resend._domainkey` (DKIM)
   - `CNAME` `rsend` → `resend-apne1.forge.rmta.net` dan `CNAME` `send` → `send.forge.rmta.net` (SPF/return-path), DNS only

   Semua di subdomain, sehingga tidak bentrok dengan MX Email Routing di root (§8.3). Biarkan **Enable receiving** di Resend mati, karena email masuk ditangani Cloudflare Email Routing.
4. DMARC tidak ikut Auto configure. Tambahkan manual di Cloudflare: `TXT` dengan nama `_dmarc`, nilai `v=DMARC1; p=none;`.
5. Kembali ke Resend, klik **Verify DNS Records**. Tunggu sampai status *Verified* (biasanya beberapa menit, paling lama sekitar 1 jam).
6. **API Keys > Create API Key**: nama `supabase-meowville`, permission **Sending access**, domain `najer.dev`. Salin key (diawali `re_`). Key hanya tampil sekali. Simpan di password manager dan **jangan** masukkan ke repo atau `.env` app.

Kuota free tier sekitar 3.000 email/bulan dan 100/hari, cukup untuk testing dan closed testing.

### 8.2 Supabase (memakai Resend)

1. Supabase Dashboard > project production > **Authentication > Emails > SMTP Settings** > aktifkan *Enable custom SMTP*.
2. Isi:

   | Field | Nilai |
   |---|---|
   | Sender email | `no-reply@najer.dev` |
   | Sender name | `Meowville` |
   | Host | `smtp.resend.com` |
   | Port | `465` |
   | Username | `resend` |
   | Password | API key `re_…` dari §8.1 |
   | Minimum interval | 60 detik (bawaan) |

3. Save.
4. **Authentication > Emails > Templates > Reset Password**: ganti subject menjadi `Kode reset kata sandi Meowville` dan body menjadi:
   ```html
   <h2>Reset kata sandi Meowville</h2>
   <p>Masukkan kode berikut di aplikasi Meowville:</p>
   <p style="font-size:28px;font-weight:bold;letter-spacing:6px">{{ .Token }}</p>
   <p>Kode berlaku 30 menit. Abaikan email ini jika kamu tidak meminta reset.</p>
   ```
   `{{ .Token }}` adalah kode 6 digit yang dibaca layar "Kode Berhasil Dikirim" di app. Template default berisi link `{{ .ConfirmationURL }}`; itulah penyebab email yang kamu terima tidak punya kode.
5. **Templates > Confirm signup**: terjemahkan ke Bahasa Indonesia. Link `{{ .ConfirmationURL }}` boleh dipertahankan.
6. **Authentication > Sign In / Providers > Email**: Email OTP expiration `1800` (30 menit), **Email OTP length `6`** (project baru default 8, sedangkan app hanya menerima 6 digit), Minimum password length `8`.
7. **Authentication > URL Configuration**: Site URL `https://meowville.najer.dev/verified`. Redirect URLs: tambahkan `https://meowville.najer.dev/**`. Jika situs belum terbit, link verifikasi tetap mendarat di URL ini dan akan berfungsi begitu situs online.
8. **Authentication > Rate Limits**: setelah custom SMTP aktif, naikkan *emails per hour* menjadi 30.
9. **Uji**: di app, buka Lupa kata sandi dengan email sendiri. Email harus datang dari `Meowville <no-reply@najer.dev>`, berisi kode 6 digit, dan alur berhasil sampai login dengan kata sandi baru. Jika tidak masuk, cek Resend > **Emails** (status *delivered*, *bounced*, atau error) dan folder Spam.

### 8.3 Cloudflare Email Routing (menerima email support)

1. Cloudflare > `najer.dev` > **Email > Email Routing** > Get started. Cloudflare menambahkan record MX dan SPF di root secara otomatis; setujui.
2. **Destination addresses**: tambahkan Gmail pribadi, lalu klik link verifikasi yang dikirim ke Gmail tersebut.
3. **Routing rules > Create address**: `meowville@najer.dev` → teruskan ke Gmail pribadi.
4. Uji: kirim email dari akun lain ke `meowville@najer.dev`. Email harus masuk ke Gmail.

Opsional, supaya balasan juga keluar sebagai `meowville@najer.dev`: Gmail > Settings > Accounts and Import > **Send mail as** > Add another email address > `meowville@najer.dev`, SMTP server `smtp.resend.com`, port `465`, username `resend`, password = API key Resend (sebaiknya buat key terpisah, misalnya `gmail-send-as`).

### 8.4 Jika ada masalah

| Gejala | Penyebab umum |
|---|---|
| Domain Resend tidak pernah *Verified* | Record diketik dengan nama lengkap (`resend._domainkey.najer.dev`) padahal Cloudflare otomatis menambahkan `.najer.dev`. Isi nama pendeknya saja. |
| Email masuk Spam | DMARC belum ada, atau isi email hanya berupa link. Tambahkan DMARC dan teks yang jelas. |
| Supabase: "Error sending recovery email" | Password SMTP salah, atau key tidak punya *Sending access* ke domain itu. |
| Template tidak bisa diedit | Supabase meminta custom SMTP aktif lebih dulu. Selesaikan §8.2 langkah 1–3. |

## 9. Kriteria selesai

- [ ] Semua URL di §4 terbuka lewat HTTPS tanpa login, di desktop dan HP 360 px.
- [ ] Halaman bukan PDF, tidak di-geoblock, dan tidak bisa diedit pengunjung.
- [ ] Privacy policy menyebut nama app dan nama developer yang sama dengan Play Console, serta sesuai jawaban Data safety di `RELEASE_READINESS.md` §6.
- [ ] Tidak ada request ke domain pihak ketiga (cek tab Network: hanya `meowville.najer.dev`).
- [ ] Header §6 aktif (cek di securityheaders.com).
- [ ] Email reset dari production berisi kode 6 digit, dikirim dari `no-reply@najer.dev`, dan alur lupa kata sandi di app berhasil sampai login dengan kata sandi baru.
- [ ] Klik link verifikasi signup mendarat di `/verified`.
- [ ] Email ke `meowville@najer.dev` masuk ke inbox pribadi.
