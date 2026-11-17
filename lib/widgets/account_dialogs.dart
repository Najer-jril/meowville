import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/booking_controller.dart';
import '../controllers/session_loader.dart';
import '../core/api_client.dart';
import '../data/models.dart';
import '../routes/app_routes.dart';
import 'common.dart';

/// Konfirmasi logout, dipakai bersama di halaman akun admin, sitter, dan owner.
Future<void> confirmLogout(BuildContext context) async {
  final ok = await showConfirmDialog(
    context,
    title: 'Keluar dari akun?',
    message: 'Anda perlu masuk lagi untuk mengakses Meowville.',
    confirmLabel: 'Keluar',
    destructive: true,
    icon: Icons.logout,
  );
  if (!ok || !context.mounted) return;
  resetSessionData(context);
  await context.read<AuthController>().signOut();
  if (context.mounted) {
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }
}

/// Hapus akun permanen (wajib menurut kebijakan Play Store). Owner harus
/// menyelesaikan atau membatalkan reservasi aktif dulu, supaya foto tidak
/// terhapus untuk akun yang nanti ditolak dihapus oleh server.
Future<void> confirmDeleteAccount(BuildContext context) async {
  final auth = context.read<AuthController>();
  final hasActive =
      auth.user?.role == UserRole.owner &&
      context.read<BookingController>().reservations.any(
        (r) => r.status.isActive,
      );
  if (hasActive) {
    return showInfoDialog(
      context,
      title: 'Belum bisa dihapus',
      message: 'Masih ada reservasi aktif. Batalkan atau selesaikan dulu.',
    );
  }
  final ok = await showConfirmDialog(
    context,
    title: 'Hapus akun?',
    message:
        'Akun, data kucing, dan riwayat reservasi akan dihapus permanen. '
        'Tindakan ini tidak bisa dibatalkan.',
    confirmLabel: 'Hapus akun',
    destructive: true,
    icon: Icons.delete_forever_outlined,
  );
  if (!ok || !context.mounted) return;
  try {
    await auth.deleteAccount();
  } on ApiException catch (e) {
    if (context.mounted) showSnack(context, e.message);
    return;
  }
  if (!context.mounted) return;
  resetSessionData(context);
  final messenger = ScaffoldMessenger.of(context);
  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  messenger.showSnackBar(
    const SnackBar(content: Text('Akun berhasil dihapus')),
  );
}
