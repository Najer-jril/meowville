import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/addon_controller.dart';
import '../../core/api_client.dart';
import '../../data/models.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

class AddonListScreen extends StatelessWidget {
  const AddonListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final addons = context.watch<AddonController>();
    final text = Theme.of(context).textTheme;

    final items = [
      ...addons.addons.where((a) => a.active),
      ...addons.addons.where((a) => !a.active),
    ];
    final active = addons.active.length;

    return Scaffold(
      appBar: const SubPageAppBar(title: 'Layanan Tambahan'),
      body: RefreshIndicator(
        onRefresh: () => addons.load(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          child: Column(
            spacing: AppSpacing.lg,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$active aktif dan ${items.length - active} nonaktif',
                      style: text.bodySmall!.copyWith(fontSize: 14),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.adminAddOnForm),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah'),
                  ),
                ],
              ),
              if (addons.loading && items.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (addons.error != null && items.isEmpty)
                ErrorState(message: addons.error!, onRetry: () => addons.load())
              else if (items.isEmpty)
                const EmptyState(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Belum ada layanan',
                  message:
                      'Tambahkan layanan seperti grooming atau antar '
                      'jemput.',
                )
              else
                for (final a in items) _AddonCard(addon: a),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddonCard extends StatelessWidget {
  const _AddonCard({required this.addon});

  final Addon addon;

  Future<void> _toggle(BuildContext context) =>
      runOnce(('toggle-addon', addon.id), () async {
        final addons = context.read<AddonController>();
        Future<void> set(bool active, String done) async {
          try {
            await addons.setActive(addon, active);
            if (context.mounted) showSnack(context, done);
          } on ApiException catch (e) {
            if (context.mounted) showSnack(context, e.message);
          }
        }

        if (!addon.active) {
          return set(true, '${addon.name} diaktifkan');
        }
        final ok = await showConfirmDialog(
          context,
          title: 'Nonaktifkan layanan?',
          message:
              'Layanan tidak muncul lagi saat pemesanan. Reservasi yang '
              'sudah ada tidak berubah.',
          confirmLabel: 'Nonaktifkan',
          destructive: true,
          icon: Icons.warning_amber_rounded,
        );
        if (ok) await set(false, '${addon.name} dinonaktifkan');
      });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final off = !addon.active;
    final fg = off ? AppColors.muted : null;

    return AppCard(
      color: off ? AppColors.surfaceAlt : AppColors.surface,
      shadow: !off,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.page,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              spacing: AppSpacing.sm,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: AppSpacing.sm,
                  children: [
                    Flexible(
                      child: Text(
                        addon.name,
                        style: text.titleLarge!.copyWith(
                          fontSize: 20,
                          color: fg,
                        ),
                      ),
                    ),
                    if (off) const StatusBadge.inactive(),
                  ],
                ),
                Text(
                  addon.description,
                  style: text.bodySmall!.copyWith(fontSize: 15),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    Fmt.rupiah(addon.price),
                    style: text.bodyLarge!.copyWith(
                      fontSize: 18,
                      color: off ? AppColors.muted : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opsi',
            icon: const Icon(Icons.more_vert, color: AppColors.muted),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            color: AppColors.surface,
            onSelected: (v) {
              if (v == 'edit') {
                Navigator.pushNamed(
                  context,
                  AppRoutes.adminAddOnForm,
                  arguments: addon,
                );
              } else {
                _toggle(context);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: ListTile(
                  leading: Icon(
                    Icons.power_settings_new,
                    color: off ? AppColors.success : AppColors.danger,
                  ),
                  title: Text(
                    off ? 'Aktifkan' : 'Nonaktifkan',
                    style: TextStyle(
                      color: off ? AppColors.success : AppColors.danger,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
