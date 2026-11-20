import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Foto yang dipilih di perangkat ini dan belum di-upload.
bool isLocalPhoto(String? p) => p != null && p.startsWith('/');

/// Path objek di bucket privat (bukti bayar, foto profil, foto kucing, foto
/// laporan). Perlu signed URL dulu sebelum bisa ditampilkan.
bool isPrivatePhoto(String? p) =>
    p != null &&
    !p.startsWith('http') &&
    !p.startsWith('/') &&
    !p.startsWith('assets/');

/// Menentukan jenis string foto: URL, file lokal, atau asset bawaan.
ImageProvider photoProvider(String path) {
  if (path.startsWith('http')) return NetworkImage(path);
  if (path.startsWith('/')) return FileImage(File(path));
  return AssetImage(path);
}

class AppPhoto extends StatelessWidget {
  const AppPhoto(
    this.path, {
    super.key,
    required this.size,
    this.height,
    this.radius = 16,
    this.placeholderIcon = Icons.pets,
  });

  final String? path;
  final double size;

  final double? height;
  final double radius;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final h = height ?? size;
    final placeholder = Container(
      width: size,
      height: h,
      color: AppColors.surfaceAlt,
      alignment: Alignment.center,
      child: Icon(
        placeholderIcon,
        color: AppColors.muted,
        size: (h < size ? h : size) * 0.4,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: path == null
          ? placeholder
          : StoredImage(
              path: path!,
              width: size,
              height: h,
              fallback: placeholder,
            ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.initial,
    this.photo,
    this.size = 56,
  });

  final String initial;
  final String? photo;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      ),
    );
    if (photo == null) return letter;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: StoredImage(
        path: photo!,
        width: size,
        height: size,
        fallback: letter,
      ),
    );
  }
}

/// gambar dari URL, file lokal, asset, atau path privat (lewat signed URL). [fallback] tampil selama URL dimuat dan saat gambar gagal.
class StoredImage extends StatefulWidget {
  const StoredImage({
    super.key,
    required this.path,
    required this.width,
    required this.height,
    required this.fallback,
  });

  final String path;
  final double width;
  final double height;
  final Widget fallback;

  @override
  State<StoredImage> createState() => _StoredImageState();
}

class _StoredImageState extends State<StoredImage> {
  String? _url;
  Future<String>? _pending;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(StoredImage old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) _resolve();
  }

  void _resolve() {
    _url = null;
    _pending = null;
    if (!isPrivatePhoto(widget.path)) {
      _url = widget.path;
      return;
    }
    final storage = context.read<StorageService>();
    _url = storage.cachedUrl(widget.path);
    if (_url == null) _pending = storage.resolve(widget.path);
  }

  Widget _image(String url) => Image(
    image: photoProvider(url),
    width: widget.width,
    height: widget.height,
    fit: BoxFit.cover,
    errorBuilder: (_, _, _) => widget.fallback,
  );

  @override
  Widget build(BuildContext context) {
    final url = _url;
    if (url != null) return _image(url);
    return FutureBuilder<String>(
      future: _pending,
      builder: (_, snap) =>
          snap.hasData ? _image(snap.data!) : widget.fallback,
    );
  }
}

/// Membuka foto layar penuh. Path privat diubah ke signed URL dulu.
Future<void> showPhotoViewer(
  BuildContext context,
  String path, {
  String title = 'Bukti bayar',
}) async {
  var url = path;
  if (isPrivatePhoto(path)) {
    try {
      url = await context.read<StorageService>().resolve(path);
    } on Object {
      if (context.mounted) showSnack(context, 'Foto gagal dimuat');
      return;
    }
  }
  if (!context.mounted) return;
  await Navigator.pushNamed(
    context,
    AppRoutes.photoPreview,
    arguments: {'path': url, 'title': title},
  );
}

class PhotoViewerScreen extends StatelessWidget {
  const PhotoViewerScreen({super.key, required this.path, required this.title});

  final String path;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 4,
          child: Image(
            image: photoProvider(path),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Column(
              spacing: AppSpacing.md,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long, color: Colors.white54, size: 64),
                Text(
                  'Gambar bukti pembayaran belum tersedia',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
