import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';

import '../../data/data.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';

class RoomCatalogScreen extends StatelessWidget {
  const RoomCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AdminStore>();
    final text = Theme.of(context).textTheme;
    final types = store.activeRoomTypes;

    return Scaffold(
      appBar: const SubPageAppBar(title: 'Tipe Kamar'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.xl,
        ),
        children: [
          Text(
            'Pilih kamar ternyaman untuk anabul tersayang.',
            style: text.bodyLarge!.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final t in types) ...[
            RoomTypeCard(
              type: t,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.ownerRoomDetail,
                arguments: t,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class RoomTypeCard extends StatelessWidget {
  const RoomTypeCard({super.key, required this.type, this.onTap});

  final RoomType type;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final shown = type.packages.take(3).toList();
    final more = type.packages.length - shown.length;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (_, c) => AppPhoto(
              type.photo,
              size: c.maxWidth,
              height: 160,
              placeholderIcon: Icons.bed_outlined,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  type.name,
                  style: text.titleLarge!.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
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
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final p in shown) TagChip(p),
              if (more > 0) TagChip('+$more', muted: true),
            ],
          ),
        ],
      ),
    );
  }
}
