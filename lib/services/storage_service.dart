import 'dart:io';

import '../core/api_client.dart';

abstract final class Buckets {
  static const cats = 'cat-photos';
  static const avatars = 'avatars';
  static const reports = 'report-photos';
  static const rooms = 'room-photos';
  static const proofs = 'payment-proofs';

  static const private = [avatars, cats, reports];
}

class StorageService {
  StorageService(this._api);

  final ApiClient _api;

  final Map<String, ({String url, DateTime expires})> _signed = {};
  final Map<String, Future<String>> _pending = {};

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
    return switch (bucket) {
      Buckets.proofs => path,
      Buckets.rooms => _api.publicUrl(bucket, path),
      _ => '$bucket/$path',
    };
  }

  String? cachedUrl(String photo) {
    final signed = _signed[photo];
    if (signed == null || DateTime.now().isAfter(signed.expires)) return null;
    return signed.url;
  }

  Future<String> resolve(String photo) {
    final cached = cachedUrl(photo);
    if (cached != null) return Future.value(cached);
    final pending = _pending[photo];
    if (pending != null) return pending;
    final future = _sign(photo);
    _pending[photo] = future;
    future.whenComplete(() => _pending.remove(photo)).ignore();
    return future;
  }

  Future<String> _sign(String photo) async {
    final (bucket, path) = _locate(photo);
    final url = await _api.signedUrl(bucket, path);
    _signed[photo] = (
      url: url,
      expires: DateTime.now().add(const Duration(minutes: 55)),
    );
    return url;
  }

  static (String, String) _locate(String photo) {
    for (final bucket in Buckets.private) {
      if (photo.startsWith('$bucket/')) {
        return (bucket, photo.substring(bucket.length + 1));
      }
    }
    return (Buckets.proofs, photo);
  }

  Future<String> proofUrl(String path) => resolve(path);

  void clearCache() => _signed.clear();
}
