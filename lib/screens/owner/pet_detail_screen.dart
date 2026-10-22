import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';

import '../../data/data.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';
import 'pet_list_screen.dart';

class PetDetailScreen extends StatelessWidget {
  const PetDetailScreen({super.key, required this.cat});

  final Cat cat;

  Future<void> _delete(BuildContext context) async {
    final store = context.read<AdminStore>();
    if (store.activeReservationOf(cat) != null) {
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
    store.deleteCat(cat);
    Navigator.pop(context);
    showSnack(context, '${cat.name} dihapus');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final badge = catStayBadge(context, cat);

    Widget row(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.xl,
        ),
        children: [
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Column(
              children: [
                AppPhoto(cat.photo, size: 120),
                const SizedBox(height: AppSpacing.md),
                Text(
                  cat.name,
                  style: text.headlineMedium!.copyWith(fontSize: 26),
                ),
                if (badge != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  badge,
                ],
                const SizedBox(height: AppSpacing.md),
                row(Icons.category_outlined, 'Ras', cat.breedLabel),
                const Divider(),
                row(Icons.monitor_weight_outlined, 'Berat', cat.weightLabel),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: () => _delete(context),
            style: dangerOutlinedStyle(),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Hapus Kucing'),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: Row(
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
            const SizedBox(width: AppSpacing.md),
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
