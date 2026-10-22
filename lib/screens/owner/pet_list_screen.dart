import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';

import '../../data/data.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';

class PetListScreen extends StatelessWidget {
  const PetListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AdminStore>();
    final text = Theme.of(context).textTheme;

    void add() => Navigator.pushNamed(context, AppRoutes.ownerPetForm);

    final cats = store.catsOf(store.currentOwner);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.xl,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          children: [
            Text('Kucing', style: text.headlineLarge),
            const SizedBox(height: AppSpacing.md),
            if (cats.isEmpty)
              AppCard(
                child: EmptyState(
                  icon: Icons.pets,
                  title: 'Belum ada kucing',
                  message:
                      'Tambahkan profil kucing untuk mulai memesan '
                      'kamar.',
                  action: FilledButton.icon(
                    onPressed: add,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Kucing'),
                  ),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${cats.length} kucing',
                      style: text.bodySmall!.copyWith(fontSize: 15),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: add,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final c in cats) ...[
                _CatCard(
                  cat: c,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.ownerPetDetail,
                    arguments: c,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

Widget? catStayBadge(BuildContext context, Cat cat) {
  final r = context.watch<AdminStore>().activeReservationOf(cat);
  if (r == null) return null;
  if (r.status == ReservationStatus.checkedIn) {
    return StatusBadge.booking('checked_in');
  }
  return StatusBadge(
    label: 'Reservasi ${Fmt.dayMonth(r.checkIn)}',
    style: const BadgeStyle(AppColors.primaryDeep, AppColors.primarySoft),
  );
}

class _CatCard extends StatelessWidget {
  const _CatCard({required this.cat, required this.onTap});

  final Cat cat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final badge = catStayBadge(context, cat);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          AppPhoto(cat.photo, size: 64),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.name, style: text.titleLarge),
                Text(
                  '${cat.breedLabel} - ${cat.weightLabel}',
                  style: text.bodySmall!.copyWith(fontSize: 14),
                ),
                if (badge != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  badge,
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }
}
