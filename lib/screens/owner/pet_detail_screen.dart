import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';

import '../../controllers/booking_controller.dart';
import '../../controllers/pet_controller.dart';
import '../../core/api_client.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';
import 'pet_list_screen.dart';

class PetDetailScreen extends StatelessWidget {
  const PetDetailScreen({super.key, required this.cat});

  final Cat cat;

  Future<void> _delete(BuildContext context, Cat cat) =>
      runOnce(('delete-cat', cat.id), () async {
        if (context.read<BookingController>().activeFor(cat) != null) {
          return showInfoDialog(
            context,
            title: 'Belum bisa dihapus',
            message:
                '${cat.name} masih punya reservasi aktif. Selesaikan atau '
                'batalkan reservasinya terlebih dahulu.',
          );
        }
        final ok = await showConfirmDialog(
          context,
          title: 'Hapus ${cat.name}?',
          message:
              'Profil ${cat.name} akan dihapus dari daftar. Riwayat reservasi '
              'tetap tersimpan.',
          confirmLabel: 'Hapus',
          destructive: true,
          icon: Icons.delete_outline,
        );
        if (!ok || !context.mounted) return;
        try {
          await context.read<PetController>().delete(cat);
        } on ApiException catch (e) {
          if (context.mounted) showSnack(context, e.message);
          return;
        }
        if (!context.mounted) return;
        Navigator.pop(context);
        showSnack(context, '${cat.name} dihapus');
      });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Argumen route jadi usang setelah diedit, jadi utamakan data hasil reload.
    final cat = context.watch<PetController>().cats.firstWhere(
      (c) => c == this.cat,
      orElse: () => this.cat,
    );
    final badge = catStayBadge(context, cat);

    Widget row(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          Expanded(
            child: Text(
              label,
              style: text.bodyLarge!.copyWith(color: AppColors.muted),
            ),
          ),
          Text(value, style: text.labelLarge),
        ],
      ),
    );

    return Scaffold(
      appBar: const SubPageAppBar(title: 'Detail Kucing'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.xl,
        ),
        child: Column(
          spacing: AppSpacing.xl,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.page),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppPhoto(cat.photo, size: 120),
                  ),
                  Text(
                    cat.name,
                    style: text.headlineMedium!.copyWith(fontSize: 26),
                  ),
                  if (badge != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: badge,
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: row(Icons.category_outlined, 'Ras', cat.breedLabel),
                  ),
                  const Divider(),
                  row(Icons.monitor_weight_outlined, 'Berat', cat.weightLabel),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _delete(context, cat),
              style: dangerOutlinedStyle(),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus Kucing'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: Row(
          spacing: AppSpacing.md,
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.ownerPetForm,
                  arguments: cat,
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
            ),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.ownerReservationFlow,
                  arguments: {'cat': cat},
                ),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Pesan Kamar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
