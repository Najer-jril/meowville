import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';

import '../../data/data.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'widgets/reservation_card.dart';

class ReservationListScreen extends StatefulWidget {
  const ReservationListScreen({super.key});

  @override
  State<ReservationListScreen> createState() => _ReservationListScreenState();
}

class _ReservationListScreenState extends State<ReservationListScreen> {
  static const _filters = <(String, ReservationStatus?)>[
    ('Semua', null),
    ('Menunggu', ReservationStatus.pending),
    ('Dikonfirmasi', ReservationStatus.confirmed),
    ('Lagi Nginap', ReservationStatus.checkedIn),
    ('Selesai', ReservationStatus.completed),
    ('Ditolak', ReservationStatus.rejected),
    ('Dibatalkan', ReservationStatus.cancelled),
  ];

  AdminStore get _store => context.read<AdminStore>();
  final _search = TextEditingController();
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Reservation> _visible() {
    final status = _filters[_filter].$2;
    final q = _search.text.trim().toLowerCase();
    return _store.latest.where((r) {
      if (status != null && r.status != status) return false;
      if (q.isEmpty) return true;
      return r.cat.name.toLowerCase().contains(q) ||
          r.owner.name.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AdminStore>();
    final text = Theme.of(context).textTheme;

    final items = _visible();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.xl,
                AppSpacing.page,
                0,
              ),
              sliver: SliverList.list(
                children: [
                  Text('Reservasi', style: text.headlineLarge),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Cari nama kucing atau pemilik',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.muted,
                      ),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Hapus',
                              onPressed: _search.clear,
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: FilterChipRow(
                labels: [for (final f in _filters) f.$1],
                selected: _filter,
                onSelected: (i) => setState(() => _filter = i),
              ),
            ),
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.event_note_outlined,
                  title: _search.text.isEmpty
                      ? 'Belum ada reservasi'
                      : 'Tidak ditemukan',
                  message: _search.text.isEmpty
                      ? 'Reservasi berstatus '
                            '${_filters[_filter].$1.toLowerCase()} '
                            'akan muncul di sini.'
                      : 'Coba kata kunci lain atau ganti filter status.',
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
                  itemBuilder: (context, i) => ReservationCard(
                    reservation: items[i],
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.adminReservationsDetail,
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
