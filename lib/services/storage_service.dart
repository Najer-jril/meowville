import 'dart:io';

import '../core/api_client.dart';

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

  /// Upload file yang dipilih. Mengembalikan URL publik, atau path objek
  /// kalau di bucket privat payment-proofs.
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

  /// Menghapus semua file yang di-upload user. Dipanggil sebelum akun dihapus.
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
