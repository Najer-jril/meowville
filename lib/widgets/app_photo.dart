import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../routes/app_routes.dart';

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
          : Image.asset(
              path!,
              width: size,
              height: h,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
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
      child: Image.asset(
        photo!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => letter,
      ),
    );
  }
}

Future<void> showPhotoViewer(
  BuildContext context,
  String path, {
  String title = 'Bukti bayar',
}) {
  return Navigator.pushNamed(
    context,
    AppRoutes.photoPreview,
    arguments: {'path': path, 'title': title},
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
          child: Image.asset(
            path,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long, color: Colors.white54, size: 64),
                SizedBox(height: 12),
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
