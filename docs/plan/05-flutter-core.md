# 05. Flutter Core

Perubahan bersama yang dipakai semua modul. Kerjakan sebelum menyambungkan layar (02, 03, 04).

Urutan: §1 `ApiClient`, §6 `Clock`, §2 model, §4 foto, §3 service, §5 controller, §7 sesi, §8 `main.dart`. Pola layar di §9, tabel migrasi dari `AdminStore` di §10.

## 1. `lib/core/api_client.dart`

Tambahan:

| Member | Kegunaan |
|---|---|
| `onUnauthorized` | Callback dari `AuthController`. Dipanggil saat response 401, lalu request diulang sekali |
| `put` | `PUT /auth/v1/user` untuk ganti password |
| `delete(path, [body])` | Hapus file Storage butuh body JSON |
| `insert(table, row)` | `POST /rest/v1/<table>` dengan `Prefer: return=representation`, mengembalikan baris pertama |
| `rpc(fn, params)` | `POST /rest/v1/rpc/<fn>` |
| `upload(bucket, path, bytes, contentType)` | `POST /storage/v1/object/<bucket>/<path>` dengan body biner |
| `publicUrl(bucket, path)` | URL untuk bucket public |
| `signedUrl(bucket, path)` | URL sementara untuk bucket `payment-proofs` |

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'env.dart';

class ApiException implements Exception { /* tidak berubah */ }

class ApiClient {
  String? accessToken;

  /// Refreshes the session after a 401. Returns true when a retry makes sense.
  Future<bool> Function()? onUnauthorized;

  Map<String, String> _headers(Map<String, String>? extra) => {
    'apikey': Env.supabaseKey,
    'Content-Type': 'application/json',
    if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    ...?extra,
  };

  Uri _uri(String path) => Uri.parse('${Env.supabaseUrl}$path');

  Future<dynamic> get(String path) =>
      _send(() => http.get(_uri(path), headers: _headers(null)));

  Future<dynamic> post(
    String path, [
    Object? body,
    Map<String, String>? headers,
  ]) => _send(
    () => http.post(
      _uri(path),
      headers: _headers(headers),
      body: body == null ? null : jsonEncode(body),
    ),
  );

  Future<dynamic> patch(String path, Object body) => _send(
    () => http.patch(
      _uri(path),
      headers: _headers({'Prefer': 'return=representation'}),
      body: jsonEncode(body),
    ),
  );

  Future<dynamic> put(String path, Object body) => _send(
    () => http.put(_uri(path), headers: _headers(null), body: jsonEncode(body)),
  );

  Future<dynamic> delete(String path, [Object? body]) => _send(
    () => http.delete(
      _uri(path),
      headers: _headers(null),
      body: body == null ? null : jsonEncode(body),
    ),
  );

  Future<Map<String, dynamic>> insert(String table, Object row) async {
    final rows = await post('/rest/v1/$table', row, {
      'Prefer': 'return=representation',
    });
    return (rows as List).first as Map<String, dynamic>;
  }

  Future<dynamic> rpc(String fn, [Map<String, dynamic> params = const {}]) =>
      post('/rest/v1/rpc/$fn', params);

  Future<void> upload(
    String bucket,
    String path,
    Uint8List bytes,
    String contentType,
  ) => _send(
    () => http.post(
      _uri('/storage/v1/object/$bucket/$path'),
      headers: _headers({'Content-Type': contentType}),
      body: bytes,
    ),
  );

  String publicUrl(String bucket, String path) =>
      '${Env.supabaseUrl}/storage/v1/object/public/$bucket/$path';

  Future<String> signedUrl(String bucket, String path) async {
    final json = await post('/storage/v1/object/sign/$bucket/$path', {
      'expiresIn': 3600,
    });
    return '${Env.supabaseUrl}/storage/v1${json['signedURL']}';
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    var res = await request();
    if (res.statusCode == 401 &&
        accessToken != null &&
        await (onUnauthorized?.call() ?? Future.value(false))) {
      res = await request();
    }
    return _decode(res);
  }

  // _decode dan _errorMessage tidak berubah
}
```

`_headers` dipanggil di dalam closure, jadi saat request diulang token baru ikut terpakai.

Tambahkan juga terjemahan pesan error umum di `_errorMessage` supaya user tidak melihat pesan teknis:

| Pesan dari server | Tampilkan |
|---|---|
| mengandung `room_types_prefix_key` | `Prefix sudah dipakai tipe kamar lain` |
| `JWT expired` | `Sesi berakhir, silakan login ulang` |
| `Failed host lookup` / `SocketException` (tangkap di `_send`) | `Tidak ada koneksi internet` |

Untuk koneksi putus, bungkus `request()` di `_send` dengan `try { ... } on SocketException { throw ApiException(0, 'Tidak ada koneksi internet'); }` (import `dart:io`).

## 2. `lib/data/models.dart`

Prinsip:

1. Semua entitas punya `id` dari database.
2. `operator ==` dan `hashCode` berbasis `id`. Wajib, karena layar memakai `Set<Addon>`, `c == cat`, dan `r.roomType == type`, sementara objek dibuat ulang setiap reload.
3. Tanggal tanpa jam (`check_in`, `start_date`) diparse sebagai tanggal lokal. Kirim ke server dengan `isoDate()`.
4. Harga reservasi memakai snapshot `roomPrice` dan harga addon dari `reservation_addons.price`.

Helper di atas file:

```dart
DateTime _date(Object? v) => DateTime.parse(v as String);

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
```

### Cat

```dart
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

  // breedLabel, weightLabel tidak berubah

  @override
  bool operator ==(Object other) => other is Cat && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
```

Field `owner` (objek `AppUser`) dihapus dan diganti `ownerId`. Dari pengecekan, layar tidak memakai `cat.owner`; pemilik diambil dari `reservation.owner`. Field jadi `final`, karena update sekarang lewat server lalu reload.

### RoomType

```dart
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
```

Tambah `final int id;` dan `==`/`hashCode` berbasis id. Untuk tipe kamar baru, buat `RoomType` dengan `id: 0` lalu kirim `toJson()`.

### Addon

Sama polanya: `id`, `fromJson`, `toJson` (`name`, `description`, `price`, `active`), `==`/`hashCode`.

### ReservationStatus

```dart
extension ReservationStatusX on ReservationStatus {
  static ReservationStatus parse(String key) =>
      ReservationStatus.values.firstWhere((s) => s.key == key);
  // key, holdsUnit, isActive, countsAsRevenue tidak berubah
}
```

### Reservation

```dart
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

  /// PostgREST select with every relation the screens read.
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
        Addon.fromJson({...row['addon'] as Map<String, dynamic>, 'price': row['price']}),
    ],
    unit: json['unit'] as String?,
    paymentProof: json['payment_proof'] as String?,
    adminNote: json['admin_note'] as String?,
  );

  final int id;
  final int roomPrice;
  final ReservationStatus status;
  final String? unit;
  final String? paymentProof;
  final String? adminNote;
  // cat, owner, roomType, checkIn, checkOut, createdAt, addons tetap

  int get roomTotal => roomPrice * nights;
  // nights, addonTotal, total, coversNight, overlaps tidak berubah

  @override
  bool operator ==(Object other) => other is Reservation && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
```

`id` berubah dari `String` ke `int`. Hanya `data.dart` yang memakai id string (`byId('r-dialga')`), dan file itu akan dihapus.

### UnitBlock

```dart
factory UnitBlock.fromJson(Map<String, dynamic> json) => UnitBlock(
  id: json['id'] as int,
  roomType: RoomType.fromJson(json['room_type'] as Map<String, dynamic>),
  unit: json['unit'] as String,
  start: _date(json['start_date']),
  end: _date(json['end_date']),
  reason: json['reason'] as String? ?? '',
);
```

### DailyReport

```dart
static const select =
    '*,reporter:profiles(*),reservation:reservations(${Reservation.select})';

factory DailyReport.fromJson(Map<String, dynamic> json) => DailyReport(
  id: json['id'] as int,
  reservation: Reservation.fromJson(json['reservation'] as Map<String, dynamic>),
  reporter: json['reporter'] == null
      ? null
      : AppUser.fromJson(json['reporter'] as Map<String, dynamic>),
  time: DateTime.parse(json['time'] as String).toLocal(),
  food: json['food'] as String,
  drink: json['drink'] as String,
  mood: json['mood'] as String,
  note: json['note'] as String? ?? '',
  photo: json['photo'] as String?,
);
```

`reporter` jadi nullable (akun sitter bisa dihapus). Ubah `pet_report_screen.dart:145` dan `today_screen.dart` menjadi `d.reporter?.firstName ?? 'staff'`.

### DayAvailability

```dart
factory DayAvailability.fromJson(Map<String, dynamic> json) => DayAvailability(
  roomTypeId: json['room_type_id'] as int,
  day: _date(json['day']),
  units: json['units'] as int,
  occupied: json['occupied'] as int,
  pending: json['pending'] as int,
  blocked: json['blocked'] as int,
);
```

Tambah field `roomTypeId` dan `day`.

### ReportRow dan ReportData

Pindahkan dari `data.dart` ke `models.dart` tanpa perubahan.

## 3. Services

Semua di `lib/services/`, konstruktor `XService(this._api)`, sama dengan `ProfileService`.

### `auth_service.dart` (perluasan)

| Method | Endpoint | Catatan |
|---|---|---|
| `signUp(...)` → `Future<String>` | `POST /auth/v1/signup` | Return id user baru: `((json['user'] ?? json) as Map)['id']`. Bentuk response beda tergantung "Confirm email" |
| `recover(email)` | `POST /auth/v1/recover` | Kirim kode OTP |
| `verifyRecovery(email, token)` → `Session` | `POST /auth/v1/verify` body `{type: 'recovery', email, token}` | Response sama dengan login |
| `updatePassword(password)` | `PUT /auth/v1/user` body `{password}` | Butuh token dari `verifyRecovery` |

### `profile_service.dart` (perluasan)

| Method | Endpoint |
|---|---|
| `update(id, {name, phone, photo})` → `AppUser` | `PATCH /rest/v1/profiles?id=eq.$id` |
| `setRole(id, role)` | `rpc('set_user_role', {p_user, p_role})` |
| `deleteMe()` | `rpc('delete_my_account')` |

### `cat_service.dart` (baru)

| Method | Endpoint |
|---|---|
| `fetchMine(ownerId)` | `GET /rest/v1/cats?select=*&owner_id=eq.$ownerId&deleted=is.false&order=created_at.desc` |
| `create(ownerId, {name, breed, weightKg, photo})` → `Cat` | `insert('cats', {...})` |
| `update(id, {name, breed, weightKg, photo})` → `Cat` | `PATCH /rest/v1/cats?id=eq.$id` |
| `delete(id)` | `rpc('delete_cat', {p_id})` |

### `room_service.dart` (baru)

| Method | Endpoint |
|---|---|
| `fetchAll()` | `GET /rest/v1/room_types?select=*&order=price.asc` |
| `create(RoomType)` → `RoomType` | `insert('room_types', type.toJson())` |
| `update(RoomType)` → `RoomType` | `PATCH /rest/v1/room_types?id=eq.$id` |
| `setActive(id, active)` | `PATCH ... {active}` |
| `availability({int? typeId, start, end})` → `List<DayAvailability>` | `rpc('room_availability', {p_type, p_start: isoDate(start), p_end: isoDate(end)})` |
| `fetchBlocks(from)` | `GET /rest/v1/unit_blocks?select=*,room_type:room_types(*)&end_date=gte.${isoDate(from)}&order=start_date` |
| `addBlock({typeId, unit, start, end, reason})` | `rpc('add_unit_block', {...})` |
| `removeBlock(id)` | `DELETE /rest/v1/unit_blocks?id=eq.$id` |

### `addon_service.dart` (baru)

`fetchAll()` (`order=name`), `create(Addon)`, `update(Addon)`, `setActive(id, active)`. Pola sama dengan room.

### `reservation_service.dart` (baru)

| Method | Endpoint | Dipakai |
|---|---|---|
| `fetchMine(ownerId)` | `GET /rest/v1/reservations?select=${Reservation.select}&owner_id=eq.$ownerId&order=created_at.desc` | owner |
| `fetchAll()` | `GET /rest/v1/reservations?select=${Reservation.select}&order=created_at.desc` | admin, sitter |
| `create({catId, typeId, checkIn, checkOut, addonIds, proof})` → `int` | `rpc('create_reservation', {...})` | owner |
| `cancel(id)` | `rpc('cancel_reservation', {p_id})` | owner, admin |
| `uploadProof(id, path)` | `rpc('upload_payment_proof', {p_id, p_path})` | owner |
| `approve(id, unit)` | `rpc('approve_reservation', {p_id, p_unit})` | admin |
| `reject(id, note)` | `rpc('reject_reservation', {p_id, p_note})` | admin |
| `checkIn(id)` | `rpc('check_in_reservation', {p_id})` | sitter, admin |
| `checkOut(id)` | `rpc('check_out_reservation', {p_id})` | sitter, admin |

PostgREST membatasi 1000 baris per request secara default. Cukup untuk skala sekarang. Kalau nanti lewat, tambahkan filter `created_at=gte.<tanggal>` untuk daftar dan buat RPC laporan terpisah.

### `daily_report_service.dart` (baru)

| Method | Endpoint |
|---|---|
| `fetchAll()` | `GET /rest/v1/daily_reports?select=${DailyReport.select}&order=time.desc` (RLS otomatis membatasi owner ke laporan kucingnya) |
| `create({reservationId, reporterId, food, drink, mood, note, photo})` | `insert('daily_reports', {...})` lalu ambil ulang dengan select lengkap |

### `storage_service.dart` (baru)

```dart
abstract final class Buckets {
  static const cats = 'cat-photos';
  static const avatars = 'avatars';
  static const reports = 'report-photos';
  static const rooms = 'room-photos';
  static const proofs = 'payment-proofs';
  static const all = [cats, avatars, reports, rooms, proofs];
}

class StorageService {
  StorageService(this._api);

  final ApiClient _api;

  /// Uploads a picked file. Returns the public URL, or the object path for
  /// the private payment-proofs bucket.
  Future<String> upload(String bucket, String userId, String localPath) async {
    final bytes = await File(localPath).readAsBytes();
    final ext = localPath.split('.').last.toLowerCase();
    final type = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _api.upload(bucket, path, bytes, type);
    return bucket == Buckets.proofs ? path : _api.publicUrl(bucket, path);
  }

  Future<String> proofUrl(String path) => _api.signedUrl(Buckets.proofs, path);

  /// Removes every file the user uploaded. Called before account deletion.
  Future<void> deleteOwnFiles(String userId) async {
    for (final bucket in Buckets.all) {
      final files = await _api.post('/storage/v1/object/list/$bucket', {
        'prefix': userId,
        'limit': 1000,
      }) as List;
      if (files.isEmpty) continue;
      await _api.delete('/storage/v1/object/$bucket', {
        'prefixes': [for (final f in files) '$userId/${f['name']}'],
      });
    }
  }
}
```

## 4. Foto

### Dependency

```yaml
dependencies:
  image_picker: ^1.1.2
```

Cek versi terbaru dengan `flutter pub add image_picker`. Di Android 13+ plugin ini memakai Photo Picker sistem, jadi tidak perlu permission storage. Kamera dibuka lewat intent kamera sistem, jadi tidak perlu permission `CAMERA` selama manifest tidak mendeklarasikannya (06 §1).

### `lib/widgets/photo_picker.dart` (baru)

```dart
Future<String?> pickPhoto(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Ambil foto'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Pilih dari galeri'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  final file = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1280,
    imageQuality: 80,
  );
  return file?.path;
}
```

`maxWidth` dan `imageQuality` membuat file di bawah sekitar 300 KB, jauh di bawah batas bucket 5 MB.

### Aturan string foto

Satu field `String? photo` bisa berisi empat bentuk:

| Bentuk | Contoh | Ditampilkan dengan |
|---|---|---|
| URL | `https://<ref>.supabase.co/storage/v1/object/public/...` | `Image.network` |
| Asset | `assets/images/rooms/suite.png` | `Image.asset` |
| File lokal (baru dipilih, belum diupload) | `/data/user/0/.../image_picker123.jpg` | `Image.file` |
| Path bukti bayar private | `3f2c.../1731650000000.jpg` | `PaymentProofCard` minta signed URL dulu |

Helper di `lib/widgets/app_photo.dart`:

```dart
bool isLocalPhoto(String? p) => p != null && p.startsWith('/');

ImageProvider photoProvider(String path) {
  if (path.startsWith('http')) return NetworkImage(path);
  if (path.startsWith('/')) return FileImage(File(path));
  return AssetImage(path);
}
```

Ganti `Image.asset(photo!, ...)` di `AppPhoto` dan `showPhotoViewer` menjadi `Image(image: photoProvider(photo!), ...)`. `errorBuilder` tetap.

Pola di form: tombol foto memanggil `pickPhoto`, hasilnya disimpan ke `_photo` untuk preview. Saat simpan, controller mengecek `isLocalPhoto(photo)`. Kalau lokal, upload dulu, lalu URL hasil upload yang dikirim ke database.

`PaymentProofCard`: kalau `paymentProof` bukan URL dan bukan file lokal, ambil `StorageService.proofUrl(path)` lewat `FutureBuilder`, lalu tampilkan dengan `Image.network`.

## 5. Controllers

### `lib/controllers/load_state.dart` (baru)

Pola loading dan error yang sekarang ditulis manual di `UserController`, dijadikan mixin:

```dart
mixin LoadState on ChangeNotifier {
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  Future<void> runLoad(Future<void> Function() task) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await task();
    } on Object catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
```

Aturan error:

- `load()` tidak melempar. Error disimpan di `error` dan ditampilkan di layar.
- Mutasi (`save`, `approve`, dan lain-lain) melempar `ApiException`. Layar menangkap dan menampilkan `showSnack`.
- Setiap controller punya `reset()` yang mengosongkan state. Dipanggil saat logout.

### Daftar controller

| Controller | Dipakai role | State | Method |
|---|---|---|---|
| `AuthController` (perluasan) | semua | `session`, `user` | `updateProfile`, `sendResetCode`, `resetPassword`, `deleteAccount`, `refreshNow` |
| `UserController` (perluasan) | admin | `users` | `load`, `emailTaken`, `create` (signUp lalu `setRole`) |
| `PetController` | owner | `cats` | `load`, `save`, `delete` |
| `BookingController` | owner | `reservations`, `remaining` | `load`, `create`, `uploadProof`, `cancel`, `loadRemaining`, getter |
| `RoomController` | semua | `types`, `blocks`, cache ketersediaan | `load`, `loadAvailability`, `save`, `setActive`, `addBlock`, `removeBlock`, getter |
| `AddonController` | owner, admin | `addons` | `load`, `save`, `setActive` |
| `ReservationController` | admin, sitter | `all` | `load`, `approve`, `reject`, `cancel`, `checkIn`, `checkOut`, `report`, getter |
| `DailyReportController` | semua | `reports` | `load`, `add`, getter |

Detail method per controller ada di dokumen modul: owner (02), admin (03), sitter (04).

Ketergantungan antar controller:

- `ReservationController` dan `BookingController` menerima `RoomController` di konstruktor. Setelah mutasi yang mengubah okupansi, keduanya memanggil `_rooms.refreshAvailability()`.
- `ReservationController.freeUnits` memakai `_rooms.blocks`.
- Controller yang mengupload foto menerima `StorageService` dan id user (didapat saat `load`).

## 6. `lib/utils/clock.dart`

```dart
abstract final class Clock {
  static DateTime now() => DateTime.now();

  static DateTime today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }
}
```

Ganti semua `store.today` dengan `Clock.today()` dan `store.now` dengan `Clock.now()`. Daftar lokasinya: `grep -rn "store.today\|store.now\|_store.today\|_store.now\|AdminStore>().today" lib`.

Getter yang bergantung pada "hari ini" (misalnya `awaitingCheckIn`) dihitung ulang setiap build, jadi otomatis benar saat hari berganti selama data di-refresh.

## 7. Siklus sesi

### Masuk ke home

`AppRoutes.enterHome` sekarang memanggil `AdminStore.bindAccount`. Ganti dengan:

```dart
static void enterHome(BuildContext context, AppUser user) {
  loadSessionData(context, user);
  Navigator.pushNamedAndRemoveUntil(context, homeFor(user.role), (_) => false);
}
```

`lib/controllers/session_loader.dart` (baru):

```dart
void loadSessionData(BuildContext context, AppUser user) {
  final rooms = context.read<RoomController>();
  final addons = context.read<AddonController>();
  final reports = context.read<DailyReportController>();
  switch (user.role) {
    case UserRole.owner:
      context.read<PetController>().load(user.id);
      context.read<BookingController>().load(user.id);
      rooms.load();
      addons.load();
      reports.load();
    case UserRole.admin:
      context.read<ReservationController>().load();
      context.read<UserController>().load();
      rooms.load(userId: user.id, withBlocks: true);
      rooms.loadAvailability(Clock.today(), Clock.today().add(const Duration(days: 41)));
      addons.load();
      reports.load();
    case UserRole.sitter:
      context.read<ReservationController>().load();
      reports.load();
  }
}
```

Tidak di-`await`, supaya navigasi langsung jalan dan layar menampilkan loading.

### Keluar

`confirmLogout` di `lib/widgets/session_info_card.dart:109` memanggil `AuthController.signOut()`. Tambahkan sebelum itu:

```dart
void resetSessionData(BuildContext context) {
  context.read<PetController>().reset();
  context.read<BookingController>().reset();
  context.read<RoomController>().reset();
  context.read<AddonController>().reset();
  context.read<ReservationController>().reset();
  context.read<DailyReportController>().reset();
  context.read<UserController>().reset();
}
```

Tanpa ini, data owner sebelumnya bisa terlihat sebentar kalau akun lain login di HP yang sama.

### Refresh token saat 401

Di konstruktor `AuthController`:

```dart
_api.onUnauthorized = refreshNow;
```

```dart
Future<bool>? _refreshing;

Future<bool> refreshNow() => _refreshing ??= () async {
  final current = _session;
  if (current == null) return false;
  try {
    final next = await _auth.refresh(current.refreshToken);
    _session = next;
    _api.accessToken = next.accessToken;
    if (_remembered) await _storage.save(next);
    _scheduleRefresh();
    return true;
  } on Object {
    return false;
  } finally {
    _refreshing = null;
  }
}();
```

`_refreshing` mencegah beberapa request yang gagal bersamaan memicu refresh berkali-kali.

## 8. `lib/main.dart`

```dart
final api = ApiClient();
final authService = AuthService(api);
final profileService = ProfileService(api);
final storage = StorageService(api);
final rooms = RoomController(RoomService(api), storage);

runApp(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => AuthController(api, authService, profileService, SessionStorage(), storage),
      ),
      ChangeNotifierProvider(create: (_) => UserController(profileService, authService)),
      ChangeNotifierProvider.value(value: rooms),
      ChangeNotifierProvider(create: (_) => AddonController(AddonService(api))),
      ChangeNotifierProvider(create: (_) => PetController(CatService(api), storage)),
      ChangeNotifierProvider(
        create: (_) => BookingController(ReservationService(api), storage, rooms),
      ),
      ChangeNotifierProvider(
        create: (_) => ReservationController(ReservationService(api), rooms),
      ),
      ChangeNotifierProvider(
        create: (_) => DailyReportController(DailyReportService(api), storage),
      ),
    ],
    child: const MyApp(),
  ),
);
```

`AdminStore` tetap terdaftar selama migrasi layar, lalu dihapus di D2-10.

## 9. Pola layar

Daftar data:

```dart
final pets = context.watch<PetController>();
if (pets.loading && pets.cats.isEmpty) {
  return const Center(child: CircularProgressIndicator());
}
if (pets.error != null && pets.cats.isEmpty) {
  return ErrorState(message: pets.error!, onRetry: () => pets.load());
}
return RefreshIndicator(
  onRefresh: () => pets.load(),
  child: ListView(/* isi lama */),
);
```

`ErrorState` ditambahkan ke `lib/widgets/common.dart`, meniru `EmptyState` (baris 245) dengan tambahan tombol "Coba lagi". `RefreshIndicator` butuh child yang bisa di-scroll; untuk layar kosong pakai `ListView` dengan `physics: const AlwaysScrollableScrollPhysics()`.

Submit form:

```dart
Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _saving = true);
  try {
    await context.read<PetController>().save(/* ... */);
    if (mounted) Navigator.pop(context);
  } on ApiException catch (e) {
    if (mounted) showSnack(context, e.message);
  } finally {
    if (mounted) setState(() => _saving = false);
  }
}
```

Tombol submit `onPressed: _saving ? null : _submit`, supaya tidak terkirim dua kali.

Aksi dari daftar (approve, check-in, batal): pola yang sama, tanpa `Navigator.pop`.

## 10. Peta migrasi `AdminStore`

Setiap member `AdminStore` yang dipakai layar dan penggantinya:

| `AdminStore` | Pengganti |
|---|---|
| `today`, `now` | `Clock.today()`, `Clock.now()` |
| `currentOwner`, `currentSitter`, `currentAdmin`, `bindAccount` | `context.watch<AuthController>().user!` |
| `users`, `emailTaken`, `addUser` | `UserController` (sudah ada) |
| `roomTypes`, `activeRoomTypes`, `prefixTaken`, `saveRoomType`, `setRoomTypeActive` | `RoomController` |
| `blocks`, `blocksFor`, `addBlock`, `removeBlock` | `RoomController` |
| `availability(type, day)` | `RoomController.availability(type, day)` dari cache RPC |
| `remainingFor(type, start, end)` | `BookingController.remaining[type.id]` setelah `loadRemaining(start, end)` |
| `totalActiveUnits` | `RoomController.totalActiveUnits` |
| `addons`, `saveAddon`, `setAddonActive` | `AddonController` |
| `catsOf`, `addCat`, `updateCat`, `deleteCat` | `PetController` |
| `activeReservationOf`, `clashFor`, `reservationsOf`, `createReservation`, `uploadProof`, `proofDeadline` | `BookingController` |
| `cancel` (owner) | `BookingController.cancel` |
| `cancel` (admin), `approve`, `reject`, `freeUnits`, `pending`, `latest`, `activeReservationCount`, `report` | `ReservationController` |
| `checkIn`, `checkOut`, `checkInsToday`, `checkOutsToday`, `staying`, `awaitingCheckIn`, `stayingNotLeaving`, `dueCheckOut` | `ReservationController` |
| `reports`, `reportToday`, `reportHistory`, `addReport` | `DailyReportController` |
| `updateProfile` | `AuthController.updateProfile` |

Setelah semua layar pindah: hapus `lib/data/data.dart`, hapus `ChangeNotifierProvider(create: (_) => AdminStore())` dari `main.dart`, hapus `bindAccount` dari `app_routes.dart`, lalu `flutter analyze` sampai bersih.
