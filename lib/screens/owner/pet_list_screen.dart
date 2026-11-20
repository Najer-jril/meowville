import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';

import '../../controllers/booking_controller.dart';
import '../../controllers/pet_controller.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';

class PetListScreen extends StatelessWidget {
  const PetListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<PetController>();
    final text = Theme.of(context).textTheme;

    void add() => Navigator.pushNamed(context, AppRoutes.ownerPetForm);

    final cats = pets.cats;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => Future.wait([
            pets.load(),
            context.read<BookingController>().load(),
          ]),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.xl,
              AppSpacing.page,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text('Kucing', style: text.headlineLarge),
                ),
                if (pets.loading && cats.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (pets.error != null && cats.isEmpty)
                  AppCard(
                    child: ErrorState(
                      message: pets.error!,
                      onRetry: () => pets.load(),
                    ),
                  )
                else if (cats.isEmpty)
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
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Row(
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
                  ),
                  Column(
                    spacing: AppSpacing.md,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final c in cats)
                        _CatCard(
                          cat: c,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.ownerPetDetail,
                            arguments: c,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget? catStayBadge(BuildContext context, Cat cat) {
  final r = context.watch<BookingController>().activeFor(cat);
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
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: AppPhoto(cat.photo, size: AppSizes.artLg),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.name, style: text.titleLarge),
                Text(
                  '${cat.breedLabel} - ${cat.weightLabel}',
                  style: text.bodySmall!.copyWith(fontSize: 14),
                ),
                if (badge != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: badge,
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }
}
