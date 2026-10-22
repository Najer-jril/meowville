import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';

import '../../data/data.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';

class RoomDetailScreen extends StatelessWidget {
  const RoomDetailScreen({super.key, required this.type});

  final RoomType type;

  @override
  Widget build(BuildContext context) {
    context.watch<AdminStore>();
    final text = Theme.of(context).textTheme;
    final heading = text.titleLarge!.copyWith(fontWeight: FontWeight.w700);

    Widget chips(List<String> items) => Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [for (final i in items) TagChip(i)],
    );

    Widget section(IconData icon, String title, Widget child) => AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: heading),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );

    return Scaffold(
      appBar: const SubPageAppBar(title: 'Detail Tipe Kamar'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.xl,
        ),
        children: [
          LayoutBuilder(
            builder: (_, c) => AppPhoto(
              type.photo,
              size: c.maxWidth,
              height: 220,
              radius: AppRadius.card,
              placeholderIcon: Icons.bed_outlined,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    type.name,
                    style: text.headlineMedium!.copyWith(fontSize: 24),
                  ),
                ),
                Text(
                  Fmt.rupiah(type.price),
                  style: text.labelLarge!.copyWith(
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
                Text(' / malam', style: text.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          section(
            Icons.notes,
            'Deskripsi',
            Text(
              type.description,
              style: text.bodyLarge!.copyWith(color: AppColors.muted),
            ),
          ),
          if (type.facilities.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            section(Icons.hotel_outlined, 'Fasilitas', chips(type.facilities)),
          ],
          const SizedBox(height: AppSpacing.lg),
          section(Icons.card_giftcard, 'Paket bawaan', chips(type.packages)),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: FilledButton.icon(
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.ownerReservationFlow,
            arguments: {'type': type},
          ),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Pilih tipe ini'),
        ),
      ),
    );
  }
}
