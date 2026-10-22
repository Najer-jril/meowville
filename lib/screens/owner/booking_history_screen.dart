import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';

import '../../data/data.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'widgets/owner_widgets.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  static const _filters = ['Semua', 'Aktif', 'Selesai', 'Batal & Ditolak'];

  int _filter = 0;

  bool _matches(Reservation r) => switch (_filter) {
    1 => r.status.isActive,
    2 => r.status == ReservationStatus.completed,
    3 =>
      r.status == ReservationStatus.cancelled ||
          r.status == ReservationStatus.rejected,
    _ => true,
  };

  void _book() => Navigator.pushNamed(context, AppRoutes.ownerReservationFlow);

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AdminStore>();
    final text = Theme.of(context).textTheme;

    final all = store.reservationsOf(store.currentOwner);
    final items = all.where(_matches).toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.xl,
                AppSpacing.page,
                AppSpacing.md,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Booking', style: text.headlineLarge),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${all.length} reservasi',
                            style: text.bodySmall!.copyWith(fontSize: 15),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _book,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Pesan Kamar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (all.isNotEmpty)
              SliverToBoxAdapter(
                child: FilterChipRow(
                  labels: _filters,
                  selected: _filter,
                  onSelected: (i) => setState(() => _filter = i),
                ),
              ),
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.event_note_outlined,
                  title: all.isEmpty
                      ? 'Belum ada reservasi'
                      : 'Tidak ada reservasi',
                  message: all.isEmpty
                      ? 'Reservasi kamu akan muncul di sini.'
                      : 'Belum ada reservasi di kategori ini.',
                  action: all.isEmpty
                      ? FilledButton.icon(
                          onPressed: _book,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Pesan Kamar'),
                        )
                      : null,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.md,
                  AppSpacing.page,
                  AppSpacing.xl,
                ),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.lg),
                  itemBuilder: (context, i) => OwnerBookingCard(
                    reservation: items[i],
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.ownerBookingDetail,
                      arguments: items[i],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
